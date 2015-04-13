xquery version "1.0-ml";
 
import module "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";

import module namespace cd = "http://check-database" at "/server/lib/check-database.xqy" ;
import module namespace cu = "http://check-user" at "/server/lib/check-user.xqy" ;
import module namespace to-json = "http://marklogic.com/ps/lib/to-json" at "/server/lib/l-to-json.xqy";

(: /api/users/me/ :)
declare function local:get-user(){
    cd:check-database(),
    let $user-id := xdmp:get-request-field("id")
    return 
        if (fn:not(cu:is-logged-in())) then
            fn:false()
        else
            let $role := 
                if (cu:is-admin()) then
                    "admin"
                else if (cu:is-tester()) then
                    "tester"
                else
                    "guest"       
            return 
               to-json:to-json(
                    <user>
                        <name>{xdmp:get-current-user()}</name>
                        <role>{$role}</role>
                    </user>
                )
};

local:get-user()