parse_arg <- function(x){

  #special for json obj
  if(inherits(x, "AsIs")){
    class(x) <- utils::tail(class(x), -1);
    return(x);
  }

  #cast (e.g. for NULL)
  x <- as.character(x);

  #empty vector causes issues
  if(!length(x)){
    x <- " ";
  }

  #some special cases for json compatibility
  switch(x,
    "true" = return(as.expression(TRUE)),
    "false" = return(as.expression(FALSE)),
    "null" = return(as.expression(NULL))
  );

  #if string starts with { or [ we test for json
  if(grepl("^[ \t\r\n]*(\\{|\\[)", x)) {
    if(validate(x)) {
      return(fromJSON(x));
    }
  }

  #check if it is a session key
  if(grepl(session_regex(), x)){
    x <- paste0(x, "::.val")
  }

  #try to parse code.
  myexpr <- parse_utf8(x)

  #inject code if enabled
  if(isTRUE(config("enable.post.code"))){
    #wrap in block if more than one call
    if(length(myexpr) > 1 || (is.call(myexpr[[1]]) && identical(myexpr[[1]][[1]], quote(`=`)))){
      myexpr <- parse_utf8(paste("{", x, "}"))
    }
    collect_session_keys(myexpr)
    return(myexpr)
  }

  #otherwise check for primitive
  if(!length(myexpr)){
    return(expression());
  }

  #check if it is a boolean, number or string
  if(identical(1L, length(myexpr))) {
    #parse primitives
    if(is.character(myexpr[[1]]) || is.logical(myexpr[[1]]) || is.numeric(myexpr[[1]]) || is.name(myexpr[[1]])) {
      return(myexpr);
    }
    #parse namespaced objects foo::bar
    if(is.call(myexpr[[1]]) && identical(myexpr[[1]][[1]], quote(`::`))){
      collect_session_keys(myexpr)
      return(myexpr)
    }
  }

  #failed to parse argument
  stop("Invalid argument: ", x, ".\nThis server has disabled posting R code in arguments.");
}
