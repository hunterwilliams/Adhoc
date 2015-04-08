xquery version "1.0-ml";
 
import module "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";

import module namespace cd = "http://check-database" at "/server/lib/check-database.xqy" ;
import module namespace cu = "http://check-user" at "/server/lib/check-user.xqy" ;
import module namespace render-view = "http://render-view" at "/server/view/render-view.xqy";
import module namespace nav = "http://navigation" at "/server/view/nav.xqy";
import module namespace list-users = "http://list-users" at "/server/view/list-users-view.xqy";

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