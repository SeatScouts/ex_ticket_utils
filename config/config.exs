# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

case Mix.env do
 :test ->
  config :ex_ticket_utils, domain: "localhost"
 :dev ->
  config :ex_ticket_utils, domain: "ticketutilssandbox.com"
 :staging ->
  config :ex_ticket_utils, domain: "ticketutilssandbox.com"
 _ ->
  config :ex_ticket_utils, domain: "ticketutils.com"
end
