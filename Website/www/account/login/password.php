<?php

require(dirname(__FILE__, 4) . '/framework/loader.php');
header('Content-Type: application/json');
header('Cache-Control: no-cache, no-store, must-revalidate');
header('Pragma: no-cache');
header('Expires: 0');
http_response_code(500);

define('ERR_EMAIL_NOT_VERIFIED', 436);
define('ERR_PASSWORD_VIOLATES_RULES', 437);
define('ERR_PASSWORD_COMPROMISED', 438);
define('ERR_USERNAME_TAKEN', 439);

if (empty($_POST['email']) || BeaconUser::ValidateEmail($_POST['email']) == false || empty($_POST['password']) || empty($_POST['code']) || empty($_POST['username'])) {
	http_response_code(400);
	echo json_encode(array('message' => 'Missing parameters.'), JSON_PRETTY_PRINT);
	exit;
}

$user_id = null;
$email = $_POST['email'];
$password = $_POST['password'];
$code = $_POST['code'];
$username = trim($_POST['username']); // only used for new accounts
$allow_vulnerable = isset($_POST['allow_vulnerable']) ? filter_var($_POST['allow_vulnerable'], FILTER_VALIDATE_BOOLEAN) : false;
$database = BeaconCommon::Database();

// get the email uuid
$results = $database->Query('SELECT uuid_for_email($1) AS email_id;', $email);
$email_id = $results->Field('email_id');

// make sure the verification code matches
$results = $database->Query('SELECT * FROM email_verification WHERE email_id = $1 AND code = encode(digest($2, \'sha512\'), \'hex\');', $email_id, $code);
if ($results->RecordCount() == 0) {
	http_response_code(ERR_EMAIL_NOT_VERIFIED);
	echo json_encode(array('message' => 'Email not verified.'), JSON_PRETTY_PRINT);
	exit;
}

// get the user id if this user already has an account
$results = $database->Query('SELECT user_id FROM users WHERE email_id = $1;', $email_id);
if ($results->RecordCount() == 1) {
	$user_id = $results->Field('user_id');
} else {
	// make sure the username isn't already in use
	$results = $database->Query('SELECT email_id FROM users WHERE username = $1;', $username);
	if ($results->RecordCount() == 1) {
		http_response_code(ERR_USERNAME_TAKEN);
		echo json_encode(array('message' => 'Username is already in use by another user.'), JSON_PRETTY_PRINT);
		exit;
	}
}

// make sure the password is a good password
if (!BeaconUser::ValidatePassword($password)) {
	http_response_code(ERR_PASSWORD_VIOLATES_RULES);
	echo json_encode(array('message' => 'Password must be at least 8 characters and you should avoid repeating characters.'), JSON_PRETTY_PRINT);
	exit;
}

// check the password against haveibeenpwned, only if not already checked
if ($allow_vulnerable == false) {
	$hash = strtolower(sha1($password));
	$prefix = substr($hash, 0, 5);
	$suffix = substr($hash, 5);
	$url = 'https://api.pwnedpasswords.com/range/' . $prefix;
	$hashes = explode("\n", file_get_contents($url));
	foreach ($hashes as $hash) {
		$count = intval(substr($hash, 36));
		$hash = strtolower(substr($hash, 0, 35));
		if ($hash == $suffix && $count > 0) {
			// vulnerable
			http_response_code(ERR_PASSWORD_COMPROMISED);
			echo json_encode(array('message' => 'Password is listed as vulnerable according to haveibeenpwned.com'), JSON_PRETTY_PRINT);
			exit;
		}
	}
}

$new_user = false;
if (is_null($user_id)) {
	$new_user = true;
	$user = new BeaconUser();
} else {
	$user = BeaconUser::GetByUserID($user_id);
}

$public_key = null;
$private_key = null;
BeaconEncryption::GenerateKeyPair($public_key, $private_key);

$user->SetPublicKey($public_key);
if ($user->AddAuthentication($username, $email, $password, $private_key) == false && $user->ReplacePassword($password, $private_key) == false) {
	http_response_code(500);
	echo json_encode(array('message' => 'There was an error updating authentication parameters.'), JSON_PRETTY_PRINT);
	exit;
}
if ($user->Commit() == false) {
	http_response_code(500);
	echo json_encode(array('message' => 'There was an error saving the user.'), JSON_PRETTY_PRINT);
	exit;
}
$session = BeaconSession::Create($user->UserID());
$token = $session->SessionID();

$response = array(
	'session_id' => $token
);

if ($new_user) {
	$headers = 'From: "Beacon Support" <forgotmyparachute@beaconapp.cc>';
	$subject = 'Welcome to Beacon';
	$body = "You just created a Beacon Account, which means you can easily share your documents with multiple devices. You can also link accounts like Discord, Nitrado, and Patreon to your Beacon Account. You can manage your account at <https://beaconapp.cc/account/> to change your password, link accounts, manage documents, and delete your account. Though let's hope you don't want to do that last one.\n\nFor reference, you can view Beacon's privacy policy at <https://beaconapp.cc/privacy.php>. The TL;DR of it is simple: your data is yours and won't be sold or monetized in anyway.\n\nHave fun and happy looting!\nThom McGrath, developer of Beacon.";
	mail($email, $subject, $body, $headers);
}

http_response_code(200);
echo json_encode($response, JSON_PRETTY_PRINT);

?>