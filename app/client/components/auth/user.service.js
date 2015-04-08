'use strict';

angular.module('demoApp')
  .factory('User', function ($resource) {
    return $resource('/api/users/:id', {
      id: '@_id'
    },
    {
      changePassword: {
        method: 'PUT',
        params: {
          controller:'password'
        }
      },
      get: {
        method: 'GET',
        params: {
          id:'me'
        }
      }
	  });
  });
