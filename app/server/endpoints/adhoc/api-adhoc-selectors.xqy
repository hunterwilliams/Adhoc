xquery version "1.0-ml";
import module namespace la = "http://marklogic.com/ps/lib/adhoc" at "/server/lib/l-adhoc.xqy";
import module namespace to-json = "http://marklogic.com/data-explore/lib/to-json" at "/server/lib/to-json-lib.xqy";
(: Expected output 

    ['Documents','other',....]
:)
(: address.com:port/api/adhoc/:database/:doctype :)
declare function local:get-doctypes-json($db as xs:string){
    let $doctypes := la:get-doctypes($db)

    let $array-json := to-json:seq-to-array-json(to-json:string-sequence-to-json($doctypes))

    return $array-json
};
declare function local:get-queries-views-json($db as xs:string, $doctype as xs:string){
    let $queries := la:get-query-names($db,$doctype)
    let $views 	 := la:get-view-names($db,$doctype)

    let $queries-array-sequence := 
        for $q in $queries
        let $options := to-json:seq-to-array-json(to-json:string-sequence-to-json(la:get-query-form-items($doctype,$q)))
        return to-json:xml-obj-to-json(<output><query>{$q}</query><form-options>{$options}</form-options></output>)

    let $queries-json := to-json:seq-to-array-json($queries-array-sequence)
    let $views-json   := to-json:seq-to-array-json(to-json:string-sequence-to-json($views))
    
    let $json := to-json:xml-obj-to-json(<output><queries>{$queries-json}</queries><views>{$views-json}</views></output>)
    return $json
};

declare function local:get-json(){
	let $path 	 := xdmp:get-original-url()
	let $tokens  := fn:tokenize($path, "/")
	let $db 	 := $tokens[4]
	let $doctype := $tokens[5]

	return 
		if (fn:empty($doctype) or $doctype = "") then
			local:get-doctypes-json($db)
		else
			local:get-queries-views-json($db,$doctype)
};

local:get-json()