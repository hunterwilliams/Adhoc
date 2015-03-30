xquery version "1.0-ml";
 
module namespace get-workspaces = "http://get-workspaces" ;

import module namespace cd = "http://check-database" at "/server/lib/check-database.xqy" ;
import module namespace cu = "http://check-user" at "/server/lib/check-user.xqy" ;

declare namespace qconsole="http://marklogic.com/appservices/qconsole";


declare function get-workspaces:mlum-get()  {
  let $user-id := cu:get-user-id("admin")
  let $eval :=
    fn:concat(
        'xquery version "1.0-ml"; ',
        'declare namespace qconsole="http://marklogic.com/appservices/qconsole"; ',
        'let $user-id-q := cts:element-value-query(xs:QName("qconsole:userid"), fn:string("', 
        $user-id, 
        '")) ',
        'let $ws := cts:search(fn:doc()/qconsole:workspace, $user-id-q) ',
        'return $ws'
    )
  (:  
  let $_ := xdmp:log("get-workspaces:mlum-get() eval: ") 
  let $_ := xdmp:log($eval) :)
  
  let $options := 
    <options xmlns="xdmp:eval">
        <database>{xdmp:database("App-Services")}</database> 
    </options>
  
   let $workspaces := xdmp:eval($eval, (), $options)   
    
  return $workspaces
  
};


