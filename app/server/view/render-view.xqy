xquery version "1.0-ml";

module namespace render-view = "http://render-view" ;

import module namespace cfg = "http://www.marklogic.com/ps/lib/config" at "/server/lib/config.xqy";
import module namespace  cu = "http://check-user" at "/server/lib/check-user.xqy" ;
import module namespace nav = "http://navigation" at "/server/view/nav.xqy";


declare function render-view:display(
    $title as xs:string,
    $html as node()*)
{
    xdmp:set-response-content-type("text/html; charset=UTF-8"),
    '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
    <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
            <meta http-equiv="Content-Style-Type" content="text/css"></meta>
            <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"></meta>
            <meta name="viewport" content="width=device-width, initial-scale=1"></meta>
            <title>{$cfg:app-title} - {$title}</title>

    		<link rel="stylesheet" href="/css/bootstrap.min.css" />
            <link rel="stylesheet" href="/css/jquery-ui.css" />

            <script type="text/javascript" src="/js/jquery-1.11.2.min.js"></script>
            <script type="text/javascript" src="/js/jquery-ui.min.js"></script>
            <script type="text/javascript" src="/js/app.js"></script>
            <script type="text/javascript" src="/js/bootstrap.min.js"></script>
            <script>
              $(function() {{
                $( "#startDate" ).datepicker({{
                  showOn: "both",
                  buttonImage: "images/calendar.gif",
                  buttonImageOnly: true,
                  dateFormat: "yy-mm-dd"
                }});
              }});
              $(function() {{
                $( "#endDate" ).datepicker({{
                  showOn: "both",
                  buttonImage: "images/calendar.gif",
                  buttonImageOnly: true,
                  dateFormat: "yy-mm-dd"
                }});
              }});
            </script>
            {if (fn:contains($title,"Advanced Search")) then 
                <script type="text/javascript" src="/js/advanced-search.js" />
            else
                ()
            }
        </head>
        <body>
            <div class="container-fluid">
                <nav class="navbar navbar-default">
                    <div class="container-fluid">
                        <!-- Brand and toggle get grouped for better mobile display -->
                        <div class="navbar-header">
                          <a class="navbar-brand" href="/">{$cfg:app-title}</a>
                        </div>
                            {nav:show-links()}
                    </div>
                </nav>
                {
                    if(cu:is-logged-in()) then
                        <p class="text-right">{fn:format-dateTime(fn:current-dateTime(),"[M01]/[D01]/[Y0001] [H01]:[m01]:[s01]:[f01]","en","AD","US")}</p>
                    else
                        ()
                }
                <div class="row">
                    {if(fn:not($title = ("Login","Adhoc Query","Logout Result","Login Result","Monthly Report - IRS Batch"))) then
                        <div class="col-md-6 col-md-offset-2">
                            <div class="panel panel-default">
                              <div class="panel-heading">
                                <h3 class="panel-title">{$title}</h3>
                              </div>
                              <div class="panel-body">
                                {$html}
                              </div>
                            </div>
                        </div>
                    else
                      $html
                    }
                </div>
            </div>
        </body>
    </html>
};

declare function render-view:displayTable(
    $title as xs:string,
    $html as node()*
) {
    xdmp:set-response-content-type("text/html; charset=UTF-8"),
    '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
    <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
            <meta http-equiv="Content-Style-Type" content="text/css"></meta>
            <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"></meta>
            <title>{$cfg:app-title} - {$title}</title>

            <!--[if lt IE 9]>
              <script src="/js/unsemantic/html5.js"></script>
            <![endif]-->
            <!--[if (gt IE 8) | (IEMobile)]><!-->
                <link rel="stylesheet" href="/css/unsemantic/app.css" />
              <link rel="stylesheet" href="/css/unsemantic/unsemantic-grid-responsive.css" />
            <!--<![endif]-->
            <!--[if (lt IE 9) & (!IEMobile)]>
              <link rel="stylesheet" href="/css/unsemantic/app-ie7.css" />
              <link rel="stylesheet" href="/css/unsemantic/ie.css" />
            <![endif]-->

            <script type="text/javascript" src="/js/jquery-1.5.2.min.js"></script>
            <script type="text/javascript" src="/js/jquery-ui-1.8.18.custom.min.js"></script>
            <script type="text/javascript" src="/js/app.js"></script>
        </head>
        <body class="backdrop">
            <div id="container" class="grid-container" style="max-width:1400px;overflow: auto;">

                <div class="grid-100 mobile-grid-100">

                    <div id="header" class="grid-100 mobile-grid-100">
                        <div class="grid-70 mobile-grid-100">
                            <a href="/"><h1>{$cfg:app-title}</h1></a>
                        </div>
                        <div id="imgContainer" class="grid-30 mobile-grid-0">
                            <div id="headerImg"/>
                        </div>
                        {



                            if(cu:is-logged-in()) then
                                <div>You are currently logged in as {xdmp:get-current-user()}</div>
                            else
                                ()
                        }
                    </div>
                    <div id="body"  class="section grid-100">
                        {$html}
                    </div>
                    <div id="footer" class="grid-100">
                        <div>Page time: {fn:format-dateTime(fn:current-dateTime(),"[M01]/[D01]/[Y0001] [H01]:[m01]:[s01]:[f01]","en","AD","US")}</div>
                    </div>
                </div>
            </div>
        </body>
    </html>
};