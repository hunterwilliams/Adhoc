'use strict';

angular.module('demoApp')
  .controller('LoginCtrl', function ($scope, Auth, $location, $window) {
    $scope.user = {};
    $scope.errors = {};

    $scope.login = function(form) {
      $scope.submitted = true;

      if(form.$valid) {
        Auth.login({
          userid: $scope.user.userid,
          password: $scope.user.password
        })
        .then( function() {
          // Logged in, redirect to home
          $location.path('/');
        })
        .catch( function(err) {
          var errorMessage = 'Error please try again..';
          if (typeof(err) === 'undefined' || err.message === ''){
            errorMessage = err.message;
          }
          $scope.errors.other = errorMessage;
        });
      }
    };
  });
