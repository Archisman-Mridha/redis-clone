import { Data } from "effect"

export type RedisError = Data.TaggedEnum<{
  InvalidRequestFormat: {}

  ParseError: { error: ParseError }

  CommandExecutionError: { error: CommandExecutionError }
}>

export type ParseError = Data.TaggedEnum<{
  UnexpectedError: {}

  InvalidUTF8Character: {}
  FailedParsingLength: {}
  UnexpectedInput: {}
  UnexpectedEndOfInput: {}
}>

export type CommandExecutionError = Data.TaggedEnum<{
  ServerError: {}

  UnknownCommand: {}
  WrongArguments: {}
  UnknownOption: {}
  WrongOperationType: {}
  KeyNotFound: {}
}>

export const {
  InvalidRequestFormat,

  ParseError,

  CommandExecutionError
} = Data.taggedEnum<RedisError>()

export const {
  UnexpectedError,

  InvalidUTF8Character,
  FailedParsingLength,
  UnexpectedInput,
  UnexpectedEndOfInput
} = Data.taggedEnum<ParseError>()

export const {
  ServerError,

  UnknownCommand,
  WrongArguments,
  UnknownOption,
  WrongOperationType,
  KeyNotFound
} = Data.taggedEnum<CommandExecutionError>()
