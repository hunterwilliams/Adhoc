xquery version "1.0-ml";
 
import module "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";

import module namespace cd = "http://check-database" at "/server/lib/check-database.xqy" ;

declare function local:login(){
    cd:check-database(),
    let $user-id := xdmp:get-request-field("userid")  
    let $password := xdmp:get-request-field("password")
    let $loggedIn := try { xdmp:login($user-id, $password) } catch ($e) { fn:false()}
    return 
        if ($loggedIn) then
            (xdmp:set-response-code(200,"Success"),$user-id)
        else
            (xdmp:set-response-code(401,"Failure"),"")
};

local:login()