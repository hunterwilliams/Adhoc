'use strict';

angular.module('demoApp')
  .controller('DetailCtrl', function ($scope, $http, $stateParams, Detail) {

    $scope.database = $stateParams.database;
    $scope.uri      = $stateParams.uri;

    $scope.details = Detail.get({database:$scope.database,uri:$scope.uri},function(details){
      $scope.doc = details;
    });
  });
