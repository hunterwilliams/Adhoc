xquery version "1.0-ml";

module namespace lib-adhoc-create = "http://marklogic.com/data-explore/lib/adhoc-create-lib";
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config"
  at "/server/lib/config.xqy";

declare variable $form-fields-map :=
	let $form-map := map:map()
	return $form-map
;

declare function lib-adhoc-create:get-elementname($xpath as xs:string, $position as xs:string){
  let $tokens := fn:tokenize($xpath, "/")
  let $elementname :=
    if ($position eq "last") then
      $tokens[fn:count($tokens)]
    else $tokens[2]
  return $elementname
};

declare function lib-adhoc-create:create-params($i){
  fn:concat('let $param', $i, ' := map:get($params, "id', $i, '")')
};

declare function lib-adhoc-create:create-evq($i, $xpath as xs:string){
 let $elementname := lib-adhoc-create:get-elementname($xpath, "last")
 return
 fn:concat('if ($param', $i, ') then cts:element-value-query(xs:QName("', $elementname, '"), $param', $i, ')
            else ()')
};

declare function lib-adhoc-create:create-eq($xpath as xs:string, $params){
 let $elementname := lib-adhoc-create:get-elementname($xpath, "root")
 return
 fn:concat('cts:element-query(
      xs:QName("', $elementname, '"), cts:and-query((',  $params, ',if ($word) then
      cts:word-query($word, "case-insensitive")
    else
      ())))')
};

declare function lib-adhoc-create:file-name($query-name as xs:string)
	as xs:string
{
	let $str := fn:replace($query-name, " ", "_")
	let $str := fn:encode-for-uri($str)
	return $str || ".xml"
};

declare function lib-adhoc-create:create-edit-form-query($adhoc-fields as map:map)
	as xs:boolean
{
	let $prefix := map:get($adhoc-fields, "prefix")
	let $root-element := map:get($adhoc-fields, "rootElement")
	let $query-name := map:get($adhoc-fields, "queryName")
	let $querytext := map:get($adhoc-fields, "queryText")
	let $database := map:get($adhoc-fields, "database")


	let $uri :=
		fn:string-join(
			("", "adhoc", $prefix, $root-element, "forms-queries", lib-adhoc-create:file-name($query-name))
		, "/")

	let $form-query :=
		<formQuery>
		  <queryName>{ $query-name }</queryName>
		  <database>{$database}</database>
		  <documentType prefix="{ $prefix }">{ $root-element }</documentType>
		  {
		  	let $counter := 1
		  	for $i in (1 to 250)
		  	let $label := map:get($adhoc-fields, fn:concat("formLabel", $i))
		  	return
		  		if (fn:exists($label)) then
		  		  let $_ := map:put($form-fields-map, fn:concat("id", $counter), map:get($adhoc-fields, fn:concat("formLabelHidden", $i)))
		  		  let $_ := xdmp:set($counter, $counter + 1)
		  		  return
		  			<formLabel>{ $label }</formLabel>
		  		else
		  			()
		  }
		  <code>{if($querytext) then $querytext else lib-adhoc-create:create-edit-form-code($adhoc-fields)}</code>
		</formQuery>
  let $_ := lib-adhoc-create:document-insert($uri, $form-query)

	return fn:true()
};

declare function lib-adhoc-create:create-edit-form-code($adhoc-fields as map:map){
	  let $params :=
	    for $key in map:keys($form-fields-map)
	    return lib-adhoc-create:create-params(fn:substring($key, 3))

	  let $word-query := fn:concat('let $word := map:get($params, "word")', fn:codepoints-to-string(10), 'return', fn:codepoints-to-string(10))
	  let $evqs :=
	    for $key in map:keys($form-fields-map)     
    	return lib-adhoc-create:create-evq(fn:substring($key, 3),  map:get($form-fields-map, $key))
    return (
    	$params, 
    	$word-query, 
    	lib-adhoc-create:create-eq(
    		map:get($adhoc-fields, fn:concat("formLabelHidden", 1)), 
    		fn:string-join($evqs, fn:concat(",", fn:codepoints-to-string(10)))
      ) 
    )
};

declare function lib-adhoc-create:create-edit-view($adhoc-fields as map:map)
	as empty-sequence()
{
	let $prefix := map:get($adhoc-fields, "prefix")
	let $root-element := map:get($adhoc-fields, "rootElement")
	let $view-name := map:get($adhoc-fields, "viewName")
	let $database := map:get($adhoc-fields, "database")
	return
		if ($prefix and $root-element and $view-name) then
			let $uri :=
				fn:string-join(
					("", "adhoc", $prefix, $root-element, "views", lib-adhoc-create:file-name($view-name))
				, "/")

			let $view :=
				<view>
				  <viewName>{ $view-name }</viewName>
				  <database>{$database}</database>
				  <documentType prefix="{ $prefix }">{ $root-element }</documentType>
				  <columns>
				  {
				  	for $i in (1 to 15)
				  	let $name := map:get($adhoc-fields, "columnName" || $i)
				  	let $expr := map:get($adhoc-fields, "columnExpr" || $i)
				  	return
				  		if (fn:exists($name) and fn:exists($expr)) then
				  			<column name="{ $name }" evaluateAs="XPath" expr="{ $expr }" />
				  		else
				  			()
				  }
					</columns>
				</view>

		  return lib-adhoc-create:document-insert($uri, $view)

		else
			fn:error((), fn:concat(("A required param is missing"," prefix",$prefix," rootElement",$root-element, " viewName",$view-name," database",$database)))
};

declare private function lib-adhoc-create:document-insert($uri as xs:string, $doc as element())
	as empty-sequence()
{
  xdmp:eval(
  	'
    declare  namespace sec="http://marklogic.com/xdmp/security";
  	declare variable $uri as xs:string external;
  	declare variable $doc as element() external;
  	declare variable $role-id as xs:unsignedLong external;

    let $perms :=
      (element sec:permission { element sec:capability {"read"},  element sec:role-id {$role-id} },
       element sec:permission { element sec:capability {"execute"},  element sec:role-id  {$role-id} }
       )

  	return xdmp:document-insert($uri, $doc, $perms)
  	',
		(
			xs:QName("uri"), $uri,
			xs:QName("doc"), $doc,
			xs:QName("role-id"), xdmp:role($cfg:management-role)
		),
    <options xmlns="xdmp:eval">
		  <database>{xdmp:database($cfg:modules-db)}</database>
		</options>
	)
};