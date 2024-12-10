
; Inject .sql("""SELECT 1 as test""") as SQL
(call 
  function: (attribute
    object: (_)
    attribute: (identifier) @_method
    (#eq? @_method "sql"))
  arguments: (argument_list
    (string 
      [
        (string_content) 
        (interpolation)
      ] 
      @injection.content
      (#set! injection.language "sql")
    )))

; Inject sql = """SELECT 1 as test""" as SQL
(assignment
  left: (identifier) @_var_name
  (#any-of? @_var_name "sql" "_sql" "query" "_query")
  right: (string
    [
      (string_content)
      (interpolation)
    ] @injection.content
    (#set! injection.language "sql")))
