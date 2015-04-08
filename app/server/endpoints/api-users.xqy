xquery version "1.0-ml";
 
import module "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";

import module namespace cd = "http://check-database" at "/server/lib/check-database.xqy" ;
import module namespace cu = "http://check-user" at "/server/lib/check-user.xqy" ;
import module namespace json = "http://marklogic.com/xdmp/json"
    at "/MarkLogic/json/json.xqy";

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
            let $custom :=
             let $config := json:config("custom")
             return 
               (map:put($config, "array-element-names",
                         ("text","point","value","operator-state",
                          "annotation","uri","qtext")),
                map:put($config, "element-namespace", 
                         "http://marklogic.com/appservices/search"),
                map:put($config, "element-namespace-prefix", "search"),
                map:put($config, "attribute-names",("warning","name")),
                map:put($config, "full-element-names",
                         ("query","and-query","near-query","or-query")),
                map:put($config, "json-children","queries"), 
                $config)        
            return 
                json:transform-to-json(
                    <user>
                        <name>{xdmp:get-current-user()}</name>
                        <role>{$role}</role>
                    </user>,
                    $custom
                )
};

local:get-user()