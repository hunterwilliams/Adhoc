xquery version "1.0-ml";

module namespace la = "http://marklogic.com/ps/lib/adhoc";
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config"
  at "/server/lib/config.xqy";

declare function la:get-databases() as xs:string*{
	for $db in xdmp:database-name(xdmp:databases())
  	where
	    fn:not(fn:contains($db, "Security"))
	    and fn:not(fn:contains($db, "Modules"))
	    and fn:not(fn:contains($db, "Trigger"))
	    and fn:not($db = ($cfg:ignoreDbs))
  	order by $db ascending
    return $db
};

declare function la:get-doctypes($database as xs:string) as xs:string*{

	let $names := cfg:get-document-types($database)
	let $log := if ($cfg:D) then xdmp:log(text{ "get-doctypes ", fn:string-join($names, ",") }) else ()
	return
	  $names
};

declare function la:get-query-names($database as xs:string, $docType as xs:string) as xs:string*{
	let $log := if ($cfg:D) then xdmp:log(text{ "get-query-names docType := [ ", $docType, "]    $database :=  [",$database,"]" }) else ()

	let $names := cfg:get-query-names($docType,$database)
	let $log := if ($cfg:D) then xdmp:log(text{ "get-query-names ", fn:string-join($names, ",") }) else ()
	return $names
};

declare function la:get-view-names($database as xs:string, $docType as xs:string) as xs:string*{
	let $log := if ($cfg:D) then xdmp:log(text{ "get-view-names docType := [ ", $docType, "]    $database :=  [",$database,"]" }) else ()

	let $names := cfg:get-view-names($docType,$database)
	let $log := if ($cfg:D) then xdmp:log(text{ "get-view-names ", fn:string-join($names, ",") }) else ()
	return $names
};

declare function la:get-query-form-items($docType as xs:string, $query as xs:string) as xs:string*{
	cfg:get-form-query($docType, $query)/formLabel
};