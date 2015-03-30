xquery version "1.0-ml";
 
module namespace get-users = "http://get-users" ;

import module "http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";

import module namespace cd = "http://check-database" at "/server/lib/check-database.xqy" ;

declare function get-users:get()  {
   let $check-db := cd:check-database()
   return fn:data(//sec:user-name)
};