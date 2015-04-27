'use strict';

angular.module('demoApp')
  .controller('AdhocCtrl', function ($scope, $http, $sce, Auth, User) {

    $scope.selectedDatabase;//Selected Database
    $scope.selectedDocType;//Selected Doctype
    $scope.databases = [];
    $scope.doctypes = [];
    $scope.queries = [];
    $scope.views = [];
    $scope.textFields = [];
    $scope.results = {};
    $scope.inputField = {};
    $scope.message = '';

    $scope.to_trusted = function(html_code) {
        return $sce.trustAsHtml(html_code);
    };
    $http.get('/api/adhoc').success(function(data, status, headers, config) {
      if (status == 200){
        $scope.databases = data;
      }
    });

    $scope.$watch('selectedDatabase', function(newValue) {
      $scope.selectedDocType = '';
      $scope.selectedQuery = '';
      $scope.selectedView = '';
       if (typeof(newValue) !== 'undefined' && newValue != ''){
          $scope.doctypes = [];
          $scope.queries = [];
          $scope.views = [];
          $http.get('/api/adhoc/'+newValue).success(function(data, status, headers, config) {
            if (status == 200){
              $scope.doctypes = data;
              if ($scope.doctypes.length > 0){
                $scope.selectedDocType = $scope.doctypes[0];
              }
            }
          });
       }
    });

    $scope.$watch('selectedDocType', function(newValue) {
      $scope.selectedQuery = '';
      $scope.selectedView = '';
      $scope.queries = [];
      $scope.views = [];
       if (typeof(newValue) !== 'undefined' && newValue != ''){
          $http.get('/api/adhoc/'+$scope.selectedDatabase+"/"+newValue).success(function(data, status, headers, config) {
            if (status == 200){
              $scope.queries = data.queries;
              $scope.views = data.views;
              if ($scope.queries.length > 0){
                $scope.selectedQuery = $scope.queries[0].query;
              }
              if ($scope.views.length > 0){
                $scope.selectedView = $scope.views[0];
              }
              
            }
          });
       }
    });

    $scope.$watch('selectedQuery', function(newValue) {
      $scope.textFields = [];
      if (typeof(newValue) !== 'undefined' && newValue != ''){
          for (var i = 0; i < $scope.queries.length; i++){
            if ($scope.queries[i].query == newValue)
            {
              $scope.textFields = $scope.queries[i]['form-options'];
              break;
            }
          }
      }
    });

    $scope.getField = function(field) {
      var input = $scope.inputField[field];
      if (typeof(input) !== 'undefined' && input !== null)
      {
        return input;
      }
      else
      {
        return '';
      }
    };

    $scope.search = function(){
      $scope.message = 'Searching....';
      $scope.results = {};
      $http.get('/api/search',{
        params:{
          database:$scope.selectedDatabase,
          docType:$scope.selectedDocType,
          queryName:$scope.selectedQuery,
          viewName:$scope.selectedView,
          id1:$scope.getField(1),
          id2:$scope.getField(2),
          id3:$scope.getField(3),
          id4:$scope.getField(4),
          id5:$scope.getField(5),
          id6:$scope.getField(6),
          id7:$scope.getField(7),
          id8:$scope.getField(8),
          id9:$scope.getField(9),
          id10:$scope.getField(10),
          id11:$scope.getField(11),
          id12:$scope.getField(12),
          id13:$scope.getField(13),
          id14:$scope.getField(14),
          id15:$scope.getField(15),
          excludeversions:1,
          excludedeleted:1,
          go:1,
          pagenumber:1
        }
      }).success(function(data, status, headers, config) {
        $scope.message = '';
        $scope.results = data;
      }).error(function(data, status){
        if (status == 500){
          $scope.message = "Server Error";
        }
      });
    };
  });
