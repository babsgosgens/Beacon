<?php

// All mod operations require authentication

require(dirname(__FILE__) . '/loader.php');

BeaconAPI::Authorize();
$user_id = BeaconAPI::UserID();

$workshop_id = BeaconAPI::ObjectID();
$method = BeaconAPI::Method();
$database = BeaconCommon::Database();

switch ($method) {
case 'GET':
	if ($workshop_id === null) {
		$mods = BeaconMod::GetAll($user_id);
		BeaconAPI::ReplySuccess($mods);
	} else {
		$mods = BeaconMod::GetByWorkshopID($user_id, $workshop_id);
		if (count($mods) == 0) {
			BeaconAPI::ReplyError('Mod not found', null, 404);
		}
		
		if (isset($_GET['action']) && strtolower($_GET['action']) === 'confirm') {
			foreach ($mods as $mod) {
				$mod->AttemptConfirmation();
			}
		}
		
		if (BeaconAPI::ObjectCount() == 1) {
			BeaconAPI::ReplySuccess($mods[0]);
		} else {
			BeaconAPI::ReplySuccess($mods);
		}
	}
	
	break;
case 'PUT':
case 'POST':
	if ($workshop_id !== null) {
		BeaconAPI::ReplyError('Do not specify a class when registering mods.');
	}
	
	if (BeaconAPI::ContentType() !== 'application/json') {
		BeaconAPI::ReplyError('Send a JSON payload');
	}
	
	$payload = BeaconAPI::JSONPayload();
	if (BeaconCommon::IsAssoc($payload)) {
		// single
		$items = array($payload);
	} else {
		// multiple
		$items = $payload;
	}
	
	$database->BeginTransaction();
	foreach ($items as $item) {
		if (!BeaconCommon::HasAllKeys($item, 'mod_id')) {
			$database->Rollback();
			BeaconAPI::ReplyError('Not all keys are present.', $item);
		}
		$workshop_id = $item['mod_id'];
	
		$results = $database->Query('SELECT user_id FROM mods WHERE workshop_id = $1 AND user_id = $2;', $workshop_id, $user_id);
		if ($results->RecordCount() == 1) {
			$database->Rollback();
			BeaconAPI::ReplyError('Mod ' . $workshop_id . ' is already registered.');
		}
		
		$workshop_item = BeaconWorkshopItem::Load($workshop_id);
		if ($workshop_item === null) {
			$database->Rollback();
			BeaconAPI::ReplyError('Mod ' . $workshop_id . ' was not found on Ark Workshop.');
		}
		
		try {
			$database->Query('INSERT INTO mods (workshop_id, name, user_id) VALUES ($1, $2, $3);', $workshop_id, $workshop_item->Name(), $user_id);
		} catch (\BeaconQueryException $e) {
			BeaconAPI::ReplyError('Mod ' . $workshop_id . ' was not registered: ' . $e->getMessage());
		}
	}
	$database->Commit();
		
	BeaconAPI::ReplySuccess();
	
	break;
case 'DELETE':
	if (($workshop_id === null) && (BeaconAPI::ContentType() === 'text/plain')) {
		$workshop_id = BeaconAPI::Body();
	}
	if (($workshop_id === null) || ($workshop_id === '')) {
		BeaconAPI::ReplyError('No mod specified');
	}
	
	$mods = BeaconMod::GetByWorkshopID($user_id, $workshop_id);
	if (count($mods) == 0) {
		BeaconAPI::ReplyError('No mods found.', null, 404);
	}
	
	$database->BeginTransaction();
	foreach ($mods as $mod) {
		$mod->Delete();
	}
	$database->Commit();
	
	BeaconAPI::ReplySuccess();
	
	break;
default:
	BeaconAPI::ReplyError('Method not allowed.', $method, 405);
	break;
}

?>