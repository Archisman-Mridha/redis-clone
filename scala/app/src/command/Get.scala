package command

import error.CommandExecutionError
import resp.Data

extension (c: Command)
  def get(): Either[CommandExecutionError, Data] = ???
