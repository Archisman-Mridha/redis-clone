package command

import error.CommandExecutionError
import resp.Data

extension (c: Command)
  def set(): Either[CommandExecutionError, Data] = ???
