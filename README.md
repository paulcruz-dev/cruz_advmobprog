# cruz_advmobprog

## Lab Activity 3: Discussion

The cart feature follows the project’s model–service–screen pattern. `Cart` and
`CartProduct` map the JSON response from DummyJSON into typed Dart objects.
`CartService` isolates HTTP work from the interface: it gets one user’s first
cart through `/carts/user/{userId}`, gets an individual cart through
`/carts/{cartId}`, and sends a selected product id and quantity through
`POST /carts/add`. `CartScreen` uses the service in a `FutureBuilder` to render
the user’s cart. When a cart item is tapped, it requests the complete product
record and opens the same `ProductDetailsScreen` used by the shop, keeping
product presentation in one place.

The navigation design keeps Shop, Cart, and Profile in the bottom bar, while
Chat is a floating action button. The chat button is hidden on `CartScreen` to
keep the cart interface focused. The Add to cart button passes the current
product id to the cart service. DummyJSON simulates this POST response instead
of persisting it on the server, so refreshing the fetched user cart returns the
API’s original sample data. `getCartById` uses `/carts/{cartId}` when the app
already knows a particular cart identifier and needs that one cart directly.

## Lab Activity 4: Discussion

This activity extends the model-service-screen pattern with authentication.
`User` is a typed model for the authenticated DummyJSON response. `UserService`
keeps login, preference storage, session restoration, and logout outside the UI.
After a successful sign-in it stores the user fields and access token with
`SharedPreferences`; on later launches, `SplashScreen` checks that token and
routes directly to the home screen when a session exists.

`SignInScreen` validates credentials and delegates the API call to
`UserService`, while `ProfileScreen` reads the saved `User` model and renders
the account information and avatar. The cart now first loads the saved user,
then passes that user id to `CartService.getCartByUserId`. This keeps the API
request tied to the current session rather than a hard-coded sample account.

## Lab Activity 5: Discussion

The application now supports two authentication workflows. DummyJSON is a
sample REST API: `UserService.loginUser` posts a username and password to
`/auth/login`, receives a sample user and token, and saves that session only on
the device. It is useful for testing UI and API request handling, but its users
and cart updates are not a secure, persistent back end. Firebase uses the
Firebase Authentication SDK instead. A user creates an email/password account,
then signs in with that email and receives a Firebase ID token which can be
refreshed by the SDK. Firebase Auth owns password handling, secure sessions,
account deletion, display-name updates, and reauthentication before a password
change.

`UserService` keeps both workflows outside the widgets. The sign-in and signup
screens validate form fields and call the service; the service stores the
profile/session, while `ProfileScreen` gets its data through
`getUserData()`. The profile adapts to the selected `LoginType`: Firebase
accounts can change their password and delete the remote account, whereas a
DummyJSON account only clears its local sample session. Logout in either the
profile or settings clears local storage, signs Firebase out when relevant, and
returns to the sign-in screen. Firebase improves this laboratory by providing
real account creation, managed token refresh, authenticated security rules for
future data, and a production-ready identity layer rather than relying only on
sample API credentials.

## Lab Activity 6: Discussion

Lab Activity 6 adds a real-time Firestore chat feature. Firebase Authentication
does not allow a mobile or web app to list every Auth account directly, so each
Firebase sign-up and sign-in writes a safe chat profile to the Firestore
`users` collection. `ChatService` streams that collection, and the chat list
filters out the current user while allowing the remaining display names and
email addresses to be searched locally.

Selecting a user opens a Firestore conversation shared by the two Firebase user
IDs. Messages are stored under `conversations/{participantIds}/messages` and
stream into the interface in real time. The detail screen separates incoming
and outgoing bubbles visually, animates new/status-changing messages with fade
and slide transitions, and shows sending, delivered, and seen states. Opening a
conversation marks received messages as seen. Firestore provides the shared,
live message store, while Firebase Auth identifies the sender and prevents the
logged-in user from appearing in their own chat list.
