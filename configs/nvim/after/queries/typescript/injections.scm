; ; extends
;
; ; SQL injection for sql template literals (both with and without generics)
; ((call_expression
;   function: [(identifier) @_name
;              (call_expression
;                function: (identifier) @_name)]
;     (#eq? @_name "sql")
;   arguments: (template_string) @injection.content)
;     (#set! injection.language "sql"))
;
; ; SQL injection for member expressions like db.sql
; ((call_expression
;   function: (member_expression
;     property: (property_identifier) @_name
;       (#eq? @_name "sql"))
;   arguments: (template_string) @injection.content)
;     (#set! injection.language "sql"))
