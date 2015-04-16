'use strict';

angular.module('demoApp')
  .controller('AdhocCtrl', function ($scope, $http, Auth, User) {

    $scope.selectedDatabase;//Selected Database
    $scope.selectedDocType;//Selected Doctype
    $scope.databases = [];
    $scope.doctypes = [];
    $scope.queries = [];
    $scope.views = [];
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
            }
          });
       }
    });
  });
