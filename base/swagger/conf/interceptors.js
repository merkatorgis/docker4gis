responseInterceptor: response => {\n
 if ((response.url.endsWith('login') \|\| response.url.endsWith('save_password')) \&\& response.ok) {\n
  const obj = response.obj[0] ? response.obj[0] : response.obj;\n
  localStorage.setItem('Authorization', 'Bearer ' + obj.token);\n
  location.reload();\n
 }
 if (response.status === 401 \|\| response.status === 403 \|\| response.url.endsWith('logout')) {\n
  localStorage.removeItem('Authorization');\n
  location.reload();\n
 }\n
 return response;\n
},\n
requestInterceptor: request => {\n
 const url = new URL(location);\n
 const searchParams = url.searchParams;\n
 if (searchParams.has('changepassword')) {\n
  const token = searchParams.get('token');\n
  if (token) {\n
   localStorage.setItem('Authorization', 'Bearer ' + token);\n
   searchParams.delete('changepassword');\n
   searchParams.delete('token');\n
   location.replace(url.href);\n
  }\n
 }\n
 request.headers.Authorization = localStorage.getItem('Authorization');\n
 if (request.headers.Authorization === null) {\n
  delete request.headers.Authorization;\n
 }\n
 return request;\n
},
