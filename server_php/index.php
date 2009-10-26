<?php

require "pauth.php";

$server = new PAuthServer("qp9hqefpuh34f", "p8h243p9g3g", "http://localhost:4000/auth/callback");

mysql_connect("localhost", "root");
mysql_select_db("auth");

function array_to_params($arr){
  foreach($arr as $key => $value)
    $arr[$key] = $key.'='.$value;
  return implode("&", $arr);
}

try {

  if($server->checkConsumerCredentials($_GET['consumer_key'], $_GET['consumer_secret'])){

    switch($_GET['action']){
      case 'request_token':
        $server->deleteOldTokens();
        echo $server->requestToken();
        break;
      
      case 'access_token':
        $server->deleteOldTokens();
        echo $server->accessToken($_GET['token'], $_GET['secret']);
        break;
      
      case 'data':
        $server->deleteOldTokens();
        echo $server->data($_GET['token'], $_GET['secret']);
        break;
      
      case 'login':
        $server->deleteOldTokens();
        $params = array_to_params(array(
          "action" => "login",
          "consumer_key" => $_GET['consumer_key'],
          "consumer_secret" => $_GET['consumer_secret'],
          "token" => $_GET['token'],
          "secret" => $_GET['secret']
        ));
      
        if(isset($_POST['submit'])){
          $login = $_POST['login'];
          $password = $_POST['password'];
        
          // auth!!
          
          if($login == "teamon" && $password == "mapex"){
            $tkn = Token::find($_GET['token'], $_GET['secret'], "request", false);
            echo $_GET['token'];
            echo "\n";
            echo $_GET['secret'];
            if($tkn) $tkn->sign(1); // user_id!
            else throw new Unauthorized("no such token");

            header('Location: '.$server->getCallbackURI());
          } else {
            $msg = "Sry...";
          }
          
          // eof auth
          
          
        } else {
          $login = "";
          $msg = "";
        }
      
        include "login.php";
        break;
    }

  } else {
    throw new Unauthorized("consumer credentials");
  }

} catch(Unauthorized $e){
  echo "ERROR: ";
  echo $e->getMessage();
}


?>