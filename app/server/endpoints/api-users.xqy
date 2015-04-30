xquery version "1.0-ml";
 
import module "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";

import module namespace cd = "http://marklogic.com/data-explore/lib/check-database-lib" at "/server/lib/check-database-lib.xqy" ;
import module namespace check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy" ;
import module namespace to-json = "http://marklogic.com/data-explore/lib/to-json" at "/server/lib/to-json-lib.xqy";

(: /api/users/me/ :)
declare function local:get-user(){
    cd:check-database(),
    let $user-id := xdmp:get-request-field("id")
    return 
        if (fn:not(check-user-lib:is-logged-in())) then
            fn:false()
        else
            let $role := 
                if (check-user-lib:is-admin()) then
                    "admin"
                else if (check-user-lib:is-explorer()) then
                    "data-explorer"
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