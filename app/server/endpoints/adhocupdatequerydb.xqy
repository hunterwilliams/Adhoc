xquery version "1.0-ml";

import module namespace cfg = "http://www.marklogic.com/ps/lib/config" at "/server/lib/config.xqy";

let $update-type := xdmp:get-request-field("updateType")
let $query := xdmp:get-request-field("query")
let $doc-type := xdmp:get-request-field("docType")
let $db-list := xdmp:get-request-field("db-list")

let $modules-db := xdmp:database($cfg:modules-db)

(: let $_ := xdmp:log("********************1  $db-list: " ||  $db-list )  :)

let $db-list := if (fn:string-length($db-list) gt 1) then fn:substring($db-list,2) else ""

(: let $_ := xdmp:log("********************2  $db-list: " ||  $db-list ) :)

let $selected-dbs-for-query := fn:tokenize($db-list,",")

(: let $_ := for $x in $selected-dbs-for-query return xdmp:log("********************3  $selected-dbs-for-query: " ||  $x ) :)

let $ml-instance-databases := xdmp:database-name(xdmp:databases())

let $root-element := if ( $update-type = "query") then "formQuery" else if ( $update-type = "view") then "view" else "bad-update-type"

let $current-query-databases :=
    xdmp:eval(
      'cts:search( /' || $root-element || ', cts:and-query((
        cts:element-value-query(xs:QName("documentType"), "' || $doc-type  || '"),
        cts:element-value-query(xs:QName("' || $update-type || 'Name"), "' || $query || '")
          ))   )/database/text()',
      (), <options xmlns="xdmp:eval">   <database>{$modules-db}</database>  </options>)


let $remove-dbs-for-query :=
	for $db in $current-query-databases
	return if ( $db = $ml-instance-databases and fn:not($db =  $selected-dbs-for-query) ) then $db else ()

 (: let $_ := for $x in $remove-dbs-for-query return xdmp:log("********************4  $remove-dbs-for-query: " ||  $x ) :)

let $add-dbs-for-query :=
	for $db in  $selected-dbs-for-query
	return if ( $db = $current-query-databases ) then () else element database {$db}

(: let $_ := for $x in $add-dbs-for-query return xdmp:log("********************5  $add-dbs-for-query: " ||  $x )  :)

let $uri :=
    xdmp:eval(
      'cts:search( /' || $root-element || ', cts:and-query((
        cts:element-value-query(xs:QName("documentType"), "' || $doc-type  || '"),
        cts:element-value-query(xs:QName("' || $update-type || 'Name"), "' || $query || '")
          ))   )[1]/base-uri()',
      (), <options xmlns="xdmp:eval">   <database>{$modules-db}</database>  </options>)

let $_ :=
	for $add-db in $add-dbs-for-query
	return
	    xdmp:eval(
	      'xdmp:node-insert-after(
	   		fn:doc("' || $uri || '")//' || $update-type || 'Name[fn:last()],
	   		element database {"' || $add-db || '"}
		   )',
	      (), <options xmlns="xdmp:eval">   <database>{$modules-db}</database>  </options>)

let $_ :=
	for $del-db in $remove-dbs-for-query
	return
	    xdmp:eval(
	      'xdmp:node-delete(
	   		fn:doc("' || $uri || '")//database[. = "' || $del-db || '"] )',
	      (), <options xmlns="xdmp:eval">   <database>{$modules-db}</database>  </options>)


(: Don't remove any DBs already on the query that are not in this instance :)


return xdmp:redirect-response("/adhocquery")
