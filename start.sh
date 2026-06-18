#!/bin/bash
set -e
systemctl start hax-bot.service hax-bot-collector.service
systemctl status hax-bot.service hax-bot-collector.service --no-pager
