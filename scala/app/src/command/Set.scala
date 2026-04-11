package command

import error.CommandExecutionError
import resp.Data
import java.time.Instant

extension (c: Command)
  def set(): Either[CommandExecutionError, Data] = ???

class SetOptions(val ex: Instant)
