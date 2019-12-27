# uFileHandlers

## Introduction

   uFileHandlers provides mechanisms for registering and calling multiple file handlers. Which handler is called is determined by the extension of the filename.

   Handlers and extensions are registered separately to provide one handler supporting multiple extensions.

   What is a file handler? A handler(as defined by this unit) is a routine that loads or saves a file. Usually handlers are groupped according to specific file types (images, video, text, models, etc.). Depending on the extension of the file to be handled the appropriate handler will be selected, and if no extension the default one will be used(if one is set).

   There are two sides to dFileHandlers. Implementing an actual handler, and using handlers.

## Technicals

### Default handler

   First registered handler is always set as the default handler if no default handler is registered. If the routines are unable to find an appropriate handler then an error will be generated.