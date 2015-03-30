xquery version "1.0-ml";

import module namespace upf = "http://update-password-form" at "/view/update-password-form.xqy" ;

import module namespace rest="http://marklogic.com/appservices/rest" at "/MarkLogic/appservices/utils/rest.xqy";
import module namespace endpoints="http://example.com/ns/endpoints" at "/lib/endpoints.xqy";

declare variable $params as map:map := rest:process-request(endpoints:request($endpoints:UPDATE-USER));


let $user-id := map:get($params, "user-id") (: xdmp:get-request-field("user-id") :)
return 
    upf:show-form($user-id)