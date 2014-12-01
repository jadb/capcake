set_if_empty :cakephp_roles, :all
set_if_empty :cakephp_flags, ''
set_if_empty :cakephp_user, :local_user

set_if_empty :linked_dirs, [
  'tmp/cache/models',
  'tmp/cache/persistent',
  'tmp/cache/views',
  'tmp/sessions',
  'tmp/tests'
]
