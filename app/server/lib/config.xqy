xquery version "1.0-ml";

module namespace cfg = "http://www.marklogic.com/ps/lib/config";

(: these properties mostly set inside the filter.propreties file :)

declare variable $cfg:app-title := "${app-title}";
declare variable $cfg:app-role := "${app-role}";
declare variable $cfg:management-role := "${management-role}";
declare variable $cfg:admin := "${admin-name}";
declare variable $cfg:modules-db := "${module-db}";

declare variable $cfg:create-user := fn:false();

declare variable $cfg:tokenize := ",";
declare variable $cfg:pagesize := 10;

(: does some debug logging when true :)
declare variable $D := fn:true();

declare variable $NS-MAP := 
  <namespaces>
    <namespace>
      <abbrv>sample</abbrv>
      <uri>http://sample.com</uri>
    </namespace>
    <namespace>
      <abbrv>sample2</abbrv>
      <uri>http://sample2.org</uri>
    </namespace>
  </namespaces>
;

declare variable $cfg:getRequestFieldsMap :=
  let $map := map:map()
  let $_ :=
    for $field in xdmp:get-request-field-names()
    return
     if (xdmp:get-request-field($field)) then
       map:put($map, $field, xdmp:get-request-field($field))
     else
        ()
  return $map
;

declare variable $cfg:namespaces := 
  let $text :=
    for $ns in $NS-MAP/namespace
    return fn:concat('declare namespace ',$ns/abbrv/text(),'="',$ns/uri/text(),'";')
  return fn:string-join($text)
;

declare variable $ignoreDbs :=
  ("App-Services", "Documents", "Extensions", "Fab", "Last-Login", "Schemas", "Security");

declare variable $defaultDb := "Documents";

declare variable $PROLOG := 
  fn:concat('
    import module namespace cfg = "http://www.marklogic.com/ps/lib/config"
      at "/server/lib/config.xqy";
    import module namespace search = "http://marklogic.com/appservices/search"
      at "/MarkLogic/appservices/search/search.xqy";',
      $cfg:namespaces,
      '
    declare option xdmp:transaction-mode "query";
    declare variable $params as map:map external;
  ')
;

(: return HTML option elements based on all DBs on the server that pass some filter conditions :)
declare function cfg:get-databases()
{
  let $dbName := (map:get($cfg:getRequestFieldsMap, "database"), $defaultDb)[1]
  for $db in xdmp:database-name(xdmp:databases())
  where fn:not(fn:contains(fn:lower-case($db),fn:lower-case($ignoreDbs)))
  order by $db ascending
  return
    if ($db = $dbName) then
      <option selected="selected">{$db}</option>
    else
      <option>{$db}</option>
};


(: returns all of the localnames of the document types that have form-query objects :)
declare function cfg:get-document-types($db as xs:string) as xs:string*
{
  let $names :=
    let $form-queries :=
      cfg:search-config("formQuery", cts:element-value-query(xs:QName("database"), $db))
    for $fq in $form-queries
    return $fq/fn:string(documentType)

  let $names := fn:distinct-values($names)

  for $name in $names
  order by $name
  return $name
};

declare function cfg:get-query-names($document-type as xs:string, $database as xs:string)
  as xs:string*
{
  let $names :=
    let $form-queries :=
      cfg:search-config("formQuery",
    cts:and-query((
            cts:element-value-query(xs:QName("documentType"), $document-type),
            cts:element-value-query(xs:QName("database"), $database)
    ))
      )
    for $fq in $form-queries
    return $fq/fn:string(queryName)

  let $names := fn:distinct-values($names)

  for $name in $names
  order by $name
  return $name
};

declare function cfg:get-form-query(
  $document-type as xs:string,
  $query-name as xs:string)
  as element(formQuery)?
{
  cfg:search-config("formQuery",
    cts:and-query((
      cts:element-value-query(xs:QName("documentType"), $document-type),
      cts:element-value-query(xs:QName("queryName"), $query-name)
    ))
  )
};

declare function cfg:get-view-names($document-type as xs:string, $database as xs:string)
  as xs:string*
{
  let $names :=
    let $views :=
      cfg:search-config("view",
    cts:and-query((
            cts:element-value-query(xs:QName("documentType"), $document-type),
            cts:element-value-query(xs:QName("database"), $database)
    ))
      )
    for $view in $views
    return $view/fn:string(viewName)

  let $names := fn:distinct-values($names)

  for $name in $names
  order by $name
  return $name
};

declare function cfg:get-view(
  $document-type as xs:string,
  $view-name as xs:string)
  as element(view)?
{
  cfg:search-config("view",
    cts:and-query((
      cts:element-value-query(xs:QName("documentType"), $document-type),
      cts:element-value-query(xs:QName("viewName"), $view-name)
    ))
  )
};


declare function cfg:search-config($source as xs:string, $query as cts:query)
{
  xdmp:eval(
    fn:concat("cts:search(/", $source, ",", $query, ")"),
    (),
    <options xmlns="xdmp:eval">
      <database>{xdmp:database($cfg:modules-db)}</database>
    </options>
  )
};

declare function cfg:delete-document($uri as xs:string) {
  xdmp:eval(
    fn:concat("xdmp:document-delete('", $uri, "')"),
    (),
    <options xmlns="xdmp:eval">
      <database>{xdmp:database($cfg:modules-db)}</database>
    </options>
  )
};