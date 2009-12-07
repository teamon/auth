<?php

class Unauthorized extends Exception {}

class Token {
  public $id, $token, $secret, $type, $signed, $created_at, $user_id;
  
  public function regenerate(){
    $this->token = md5(rand());
    $this->secret = sha1(rand());
  }
  
  public function save(){
    $this->created_at = time();
    $data = array();
    foreach(array("token", "secret", "type", "signed", "created_at", "user_id") as $e){
      $data[] = $e.'="'.mysql_real_escape_string($this->$e).'"';
    }
    $data = implode(", ", $data);
    
    if($this->id){
      mysql_query("UPDATE tokens SET $data WHERE id=".(int)$this->id);
    } else {
      mysql_query("INSERT INTO tokens SET $data");
    }
  }
  
  public function sign($user_id){
    $this->user_id = $user_id;
    $this->signed = true;
    $this->save();
  }
  
  public function toJson(){
    return json_encode(array(
      "token" => $this->token,
      "secret" => $this->secret
    ));
  }
  
  public function userToJson(){
    $users = array(1 => "teamon");
    
    return json_encode(array(
      "id" => $this->user_id,
      "login" => $users[$this->user_id]
    ));
  }
  
  public static function generateRequestToken(){
    $tkn = new Token;
    $tkn->type = "request";
    $tkn->regenerate();
    $tkn->save();
    return $tkn;
  }
  
  public static function find($token, $secret, $type, $signed){
    $res = mysql_query('SELECT * FROM tokens WHERE
      token="'.mysql_real_escape_string($token).'" AND
      secret="'.mysql_real_escape_string($secret).'" AND
      type="'.mysql_real_escape_string($type).'" AND
      signed="'.(int)$signed.'" AND
      created_at>'.(time()-86400).' LIMIT 1');

    if($res && mysql_num_rows($res) > 0){
      $row = mysql_fetch_assoc($res);

      $tkn = new Token();
      foreach($row as $key=>$value) {
        $tkn->$key = $value;
      }
      
      return $tkn;
    } else {
      return null;
    }
  }
  
  public static function deleteOld(){
    mysql_query('DELETE FROM tokens WHERE time<'.(time()-86400));
  }
  
}

class PAuthServer {
  private $consumer_key;
  private $consumer_secret;
  private $callback_uri;
  
  public function __construct($key, $secret, $callback_uri){
    $this->consumer_key = $key;
    $this->consumer_secret = $secret;
    $this->callback_uri = $callback_uri;
  }

  public function getCallbackURI(){
    return $this->callback_uri;
  }

  public function checkConsumerCredentials($key, $secret){
    return $this->consumer_key == $key && $this->consumer_secret == $secret;
  }

  public function requestToken(){
    $tkn = Token::generateRequestToken();
    return $tkn->toJson();
  }

  public function accessToken($token, $secret){
    $tkn = Token::find($token, $secret, "request", true);
    if(!$tkn) throw new Unauthorized("access token");

    $tkn->type = "access";
    $tkn->regenerate();
    $tkn->save();

    return $tkn->toJson();
  }

  public function data($token, $secret){
    $tkn = Token::find($token, $secret, "access", true);
    if(!$tkn) throw new Unauthorized("data");
    return $tkn->userToJson();
  }

  public function deleteOldTokens(){
    Token::deleteOld();
  }

}

?>