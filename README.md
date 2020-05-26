# Demo

## Spec

We will have two database tables: "users" and "users_tokens":

* "users" will have the "hashed_password", "email" and "confirmed_at" fields plus timestamps
* "users_tokens" will have "token", "context", "sent_to", "inserted_at" fields

On sign in, we need to renew the session and delete the CSRF token. The password should be limited to 80 characters, the email to 160.

Confirmation, resetting passwords, remember me, and session management will be all based on tokens. Tokens are generated randomly using `:crypto.strong_rand_bytes/1` and then hashed using sha2/sha3. The hashing helps protect against timing attacks. The hashed token is the one stored in the database, the original token is not stored.

Whenever a token is generated, a context has to be given (such as "session", "reset", etc). The context is used to avoid one token being used against its original purpose. Verifying the token will hash the token and look-up its hashed result in the database. Verification also takes a ttl. The current date is compared against the token `inserted_at + ttl` and the token is deemed as expired if enough time has passed.

For confirming e-mail addresses, we will generate a token, and e-mail it to the user. We will store the hashed token, the context ("confirm"), and store the confirmation e-mail under the `sent_to` column. Once the user clicks the link, we will verify the token, and see if the current user e-mail matches the one in the `sent_to` column. Once the token is used, it is deleted. Note we won't automatically sign the user in after confirmation - this protects us from someone getting access to the account via confirmation tokens. This also allows us to set long expiry dates in the tokens.

For resetting the password, the process is very similar. Once the link is clicked, it will go to the reset password page. The reset password page will ask for the new password and for the password confirmation. Once the user sends the form, we will verify the token and proceed to reset the password. Resetting the password will delete all tokens. Generally speaking, changing the password always deletes all tokens. Resetting the password won't sign the user in - so if anyone intercepts the token, they cannot gain access to the system as they are missing the e-mail/username.

For changing the e-mail, the user will put the new e-mail in a field. This will create a new token with change:CURRENT_EMAIL as context and the new e-mail stored in the `sent_to` column. A hashed token will be sent to the new e-mail. Once the user clicks on the e-mail link, the raw token will be hashed and we will change the user to the new e-mail as long as the hashed token and old email match to the currently signed in user. Once this is done, the token is deleted. This token will have a short expiry date by default.

## Pending for generators

    mix phx.gen.auth Account User users ...extrafields...

The authentication mechanism should be an option. Default to bcrypt for Unix systems, pdkdf2 for Windows systems. The line to config/test.exs must always be added.

## License

Copyright 2020 Dashbit

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
