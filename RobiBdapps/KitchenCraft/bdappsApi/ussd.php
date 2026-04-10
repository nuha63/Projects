<?php

ini_set('error_log', 'ussd-app-error.log');
require 'sdk_file.php';
$date_ = date("Y-m-d h:i:sa");

$appid = "APP_136199";
$apppassword = "6c585751e59c2baecd27610078b2c030";

$sender = new SmsSender("https://developer.bdapps.com/sms/send", $appid, $apppassword);

$production = true;

if ($production == false) {
    $ussdserverurl = 'http://localhost:7000/ussd/send';
} else {
    $ussdserverurl = 'https://developer.bdapps.com/ussd/send';
}

try {
    $receiver = new UssdReceiver();
    $ussdSender = new UssdSender($ussdserverurl, $appid, $apppassword);
    $subscription = new Subscription('https://developer.bdapps.com/subscription/send', $apppassword, $appid);

    $content = $receiver->getMessage();
    $address = $receiver->getAddress();
    $requestId = $receiver->getRequestID();
    $applicationId = $receiver->getApplicationId();
    $encoding = $receiver->getEncoding();
    $version = $receiver->getVersion();
    $sessionId = $receiver->getSessionId();
    $ussdOperation = $receiver->getUssdOperation();

    $status = $subscription->getStatus($address);

    try {
        $myfile = fopen("MaskNumbers_from_USSD.txt", "a+") or die("Unable to open file!");
        fwrite($myfile, $address . " Date" . $date_ . "\n");
        fclose($myfile);
    } catch (Exception $e) {
        // Log error silently
    }

    try {
        $myfile = fopen("USSD msg.txt", "a+") or die("Unable to open file!");
        fwrite($myfile, $content . "\n");
        fclose($myfile);
    } catch (Exception $e) {
        // Log error silently
    }

    $responseMsg = ($status == "REGISTERED") ? "1. unsubscribe" : "Please wait for the confirmation pop-up.";

    if ($ussdOperation == "mo-init") {
        if ($status == "REGISTERED") {
            try {
                $ussdSender->ussd($sessionId, $responseMsg, $address);
            } catch (Exception $e) {
                $ussdSender->ussd($sessionId, 'Sorry error occured try again', $address);
            }
        } else {
            try {
                $ussdSender->ussd($sessionId, $responseMsg, $address, 'mt-fin');
                $x = $subscription->subscribe($address);
            } catch (Exception $e) {
                $ussdSender->ussd($sessionId, 'Sorry error occured try again', $address);
            }
        }
    }
} catch (Exception $e) {
    file_put_contents('USSDERROR.txt', 'Some error occured');
}

?>