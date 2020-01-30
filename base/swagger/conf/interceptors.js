responseInterceptor: response => {\n
 if ((response.url.endsWith('login') \|\| response.url.endsWith('save_password')) \&\& response.ok) {\n
  const obj = response.obj[0] ? response.obj[0] : response.obj;\n
  localStorage.setItem(AUTHORIZATION, 'Bearer ' + obj.token);\n
  location.reload();\n
 }
 if (response.status === 401 \|\| response.status === 403 \|\| response.url.endsWith('logout')) {\n
  localStorage.removeItem(AUTHORIZATION);\n
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
   localStorage.setItem(AUTHORIZATION, 'Bearer ' + token);\n
   searchParams.delete('changepassword');\n
   searchParams.delete('token');\n
   location.replace(url.href);\n
  }\n
 }\n
 request.headers.Authorization = localStorage.getItem(AUTHORIZATION);\n
 if (request.headers.Authorization === null) {\n
  delete request.headers.Authorization;\n
 }\n
 if (searchParams.has('access_token')) {\n
  const access_token = searchParams.get('access_token');\n
  if (access_token) {\n
   localStorage.setItem(ACCESS_TOKEN, access_token);\n
  } else {\n
   localStorage.removeItem(ACCESS_TOKEN);\n
  }\n
  searchParams.delete('access_token');\n
  location.replace(url.href);\n
 }\n
 request.headers.access_token = localStorage.getItem(ACCESS_TOKEN);\n
 if (request.headers.access_token === null) {\n
  delete request.headers.access_token;\n
 }\n
 return request;\n
},
