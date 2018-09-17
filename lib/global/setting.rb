require 'net/http'
require 'msgpack'
require 'open3'
require 'pastel'
require 'rainbow'
require 'sqlite3'
require 'tty-command'
require 'tty-font'
require 'tty-prompt'
require 'tty-table'
require 'tty-spinner'
require 'uri'
require 'yaml'

#command symbol
$execute_symbol = Rainbow('[*]').blue
$caution_symbol = Rainbow('[!]').red
$list_symbol = Rainbow('[l]').yellow

$parenthesis_symbol = Rainbow('[').cyan
$parenthesis_end_symbol = Rainbow(']').cyan
$success_symbol = Rainbow('+').cyan
$error_symbol = Rainbow('-').red


