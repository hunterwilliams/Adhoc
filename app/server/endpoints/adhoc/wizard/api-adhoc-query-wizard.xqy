xquery version "1.0-ml";

import module namespace functx = "http://www.functx.com"
  at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config"
  at "/server/lib/config.xqy";
import module namespace lib-adhoc = "http://marklogic.com/data-explore/lib/adhoc-lib" at "/server/lib/adhoc-lib.xqy";
import module namespace lib-adhoc-create = "http://marklogic.com/data-explore/lib/adhoc-create-lib" at "/server/lib/adhoc-create-lib.xqy";
import module namespace to-json = "http://marklogic.com/data-explore/lib/to-json" at "/server/lib/to-json-lib.xqy";


declare function local:get-children-nodes($path, $node as node()) {
  let $results :=
  for $i in $node/node()
  let $ns := xs:string(fn:namespace-uri($i))
  let $root-ns-prefix := cfg:getNamespacePrefix(xs:string(fn:namespace-uri(fn:root($i))))
  let $ns-prefix := cfg:getNamespacePrefix(xs:string(fn:namespace-uri($i)))
  let $localname := fn:local-name($i)
  let $rootname := fn:local-name(fn:root($i))
  let $finalpath := if($path) then fn:concat($path, "/", $ns-prefix, ":", $localname)
                    else fn:concat($ns-prefix, ":", $localname)
  return 
    if($i/node()) then 
      (if ($i/node() instance of text()) then fn:substring(fn:concat("/", $root-ns-prefix, ":", $rootname, "/", $finalpath), 3) 
       else (), local:get-children-nodes($finalpath, $i)) 
       else ()
  return fn:distinct-values($results)
};

declare function local:render-fields($doc as node(), $type as xs:string) {
    let $label := if ($type eq "query") then "Form Field:" else "Column Name:"
    let $input1 := if ($type eq "query") then "formLabel" else "columnName"
    let $input2 := if ($type eq "query") then "formLabelHidden" else "columnExpr"
    let $json-arr := 
      for $xpath at $p in local:get-children-nodes((), $doc)
      let $tokens := fn:tokenize($xpath, "/")
      let $xml := 
        <data>
          <label>{$label}</label>
          <xpath>{local:collapse-xpath($xpath)}</xpath>
          <xpathNormal>{fn:normalize-space(fn:tokenize($xpath, "--")[1])}</xpathNormal>
        </data>
      return to-json:xml-obj-to-json($xml)
    return to-json:seq-to-array-json($json-arr)
};

declare function local:collapse-xpath($xpath as xs:string){
  let $nodes := fn:tokenize($xpath, "/")
  let $nodescount := fn:count($nodes)
  let $new-xpath := 
    if ($nodescount eq 5) then 
      fn:string-join(($nodes[2], $nodes[3], "...", $nodes[last()]), "/")
    else if ($nodescount eq 6) then
      fn:string-join(($nodes[2], $nodes[3], "...", "...", $nodes[last()]), "/")      
    else $xpath
  return <span title="{$xpath}">{$new-xpath}</span>
};

let $uploaded-doc := xdmp:unquote(xdmp:get-request-field("uploadedDoc"))
let $type := xdmp:get-request-field("type")

let $type-label := if($type eq "query") then "Query" else "View"
let $query-view-name := if($type eq "query") then "queryName" else "viewName"

let $form := 
<form name="adhocquerywizardform"  action="/createnewqueryview"  method="post">
    <h2>{fn:concat("Edit Adhoc ", $type-label)}</h2>
    <div>
      <span>{fn:concat($type-label, " Name:")}</span>
      <input type="text" name="{$query-view-name}" size="20"/>
    </div>
    <br/>
    <h3>Document Name</h3>
    <div>
      <span>Root Element:</span>&nbsp;
      {fn:local-name($uploaded-doc/node())}
      <input type="hidden" name="rootElement" size="20" value="{fn:local-name($uploaded-doc/node())}"/>
    </div><br/>
    <h3>Database Name</h3>
    <div>
      <span>Database:</span>&nbsp;
      <select name="database">{ for $d in lib-adhoc:get-databases() return <option>{$d}</option> }</select>
    </div><br/>
    <h3>Namespaces</h3>
    <div>prefix = namespace<br/><br/>{
        for $n in $cfg:NS-MAP/namespace
        return (<span>{$n/abbrv/text()} = {$n/uri/text()}</span>,<br/>)
    }</div>    
     <input type="hidden" name="prefix" size="20" value=""/>
    <br/>{ 
    if ($type eq "query") then (
      <h3>Form</h3>,
      local:render-fields($uploaded-doc, "query"),
      <br/>)
    else  (
      <h3>View</h3>,
      local:render-fields($uploaded-doc, "view"))}
    <input type="submit" name="submit" value="Submit"/>
    <input type="hidden" name="queryText" value=""/>
</form>

let $namespaces := for $n in $cfg:NS-MAP/namespace
                   return to-json:xml-obj-to-json($n)

let $fields := local:render-fields($uploaded-doc, $type)

let $xml := 
<data>
  <type>{$type-label}</type>
  <rootElement>{fn:local-name($uploaded-doc/node())}</rootElement>
  <prefix>{cfg:getNamespacePrefix(xs:string(fn:namespace-uri($uploaded-doc/node())))}</prefix>
  <databases>{to-json:seq-to-array-json(to-json:string-sequence-to-json(lib-adhoc:get-databases()))}</databases>
  <namespaces>{to-json:seq-to-array-json($namespaces)}</namespaces>
  <fields>{$fields}</fields>
</data>

let $json := to-json:xml-obj-to-json($xml)
return $json