#--- Ring Code Formatter - Complete Interactive Version with Test Suite
#--- Ring is not case sensitive, so variables can be mixed case
#--- Date..: 2025-09-04
#--- Author: Bert Mariani + Claude AI
#---
#--- NEEDS the following Library
load "dialog.ring"       // ringpm install dialog from ysdragon

#--- Configuration variables
indentSize      = 3
maxLineLength   = 80
tabSize         = 3
useSpacesOnly   = true
formatOperators = true

#-----------------------------#
#--- KEYWORDS TYPES        ---#
#-----------------------------#

#--- Define keywords that increase indentation
indentKeywords = ["new","if", "for", "while", "do", "func", "def", "class", "switch", "try", "catch", "package"]

#--- Define keywords that decrease indentation  
deindentKeywords = ["}","end", "next", "ok", "elseif", "else", "again", "but", "off"]

#--- Define keywords that are neutral (same level)
neutralKeywords = ["elseif", "else", "case", "catch", "but"]

#--- Define switch-specific keywords
switchKeywords = ["case", "on", "off"]

#--- Define block opening characters
blockOpeners = ["{"]
blockClosers = ["}"]

#--- Define operators for proper spacing
twoCharOperators = ["==", "!=", "<=", ">=", "<<", ">>", "+=", "-=", "*=", "/=", "%=", "&&", "||", "**", "++", "--"]
oneCharOperators = ["=", "+", "-", "*", "/", "%", "<", ">", "&", "|", "^"]

#--- Comment patterns
lineComment = "#"
lineComment2 = "//"
blockCommentStart = "/*"
blockCommentEnd = "*/"

MsgWarning = []
MsgErrors  = [] 


#--------------------------------#
#--- MAIN Entry Point         ---# 
#--------------------------------#

//============================
func main
    InteractiveFormatter()
	
//============================ 

func TestGUIFormatting
    see "=== GUI FORMATTING TEST ===" + nl + nl
    
    testCode = '
Load "guilib.ring"
New qApp {
win1 = new qMainWindow() {
setGeometry(100,100,600,250)
move(370,150)
setwindowtitle("Using QProgressBar")
for x = 10 to 100 step 10
new qprogressbar(win1) {
setGeometry(5*x,100,50,x)
setvalue(x)
}
next
show()
}
exec()
}
'
    
    see "Testing GUI code formatting with nested new objects and curly braces..." + nl
    ProcessAndDisplayCode(testCode)

//============================ 
func ContainsNewKeyword line
    lowerLine = lower(line)
    #--- Check if line contains "new " (with space after)
    if substr(lowerLine, "new ")
        return true
    ok
    return false


	
//============================	

func FormatRingCode codeText
    lines             = str2list(codeText)
    formattedLines    = []
    indentLevel       = 0
    inBlockComment    = false
    inSwitch          = false
    switchIndentLevel = 0
    inTry             = false
    tryIndentLevel    = 0
    
    for line in lines
        #--- Convert tabs to spaces if configured to do so
        if useSpacesOnly
            line = tabsToSpaces(line, tabSize)
        ok       
        trimmedLine = trimAll(line)
		   
        #--- Handle Empty Lines
        if len(trimmedLine) = 0
            formattedLines + ""    // Add nothing line
            loop
        ok
        
        #--- Handle Block Comments /* ... */
        if inBlockComment		
          //formattedLines + makeSpaces(indentLevel * indentSize) + trimmedLine
		  //formattedLines + trimmedLine  // <<<<< Comment in Position 1
			formattedLines + Line         // <<<<< Comment in Original Position
			
            if substr(trimmedLine, blockCommentEnd)
                inBlockComment = false
            ok
            loop
        ok
        
        #--- Check for Block Comment start
        if substr(trimmedLine, blockCommentStart) and not substr(trimmedLine, lineComment) and not substr(trimmedLine, lineComment2)		
            inBlockComment = true
			
          //formattedLines + makeSpaces(indentLevel * indentSize) + trimmedLine
		  //formattedLines + Line         // <<<<<  Comment in Original Position
            formattedLines + trimmedLine  // <<<<<  Comment in Position 1
					
            if substr(trimmedLine, blockCommentEnd)
                inBlockComment = false
            ok
            loop
        ok
        
        #--- Handle Single Line comments (both # and // at start of line)
        if startswith(trimmedLine, lineComment) or startswith(trimmedLine, lineComment2)

           //formattedLines + makeSpaces(indentLevel * indentSize) + trimmedLine
           //formattedLines + Line	        // <<<<<  Comment to Original Position	   
             formattedLines + trimmedLine	// <<<<<  Comment to Position 1	
			 
						
            loop
        ok
        
        #--- Check for In-Line comments (code followed by // or #)
        inlineCommentPos = 0
        tempLine = trimmedLine
        
        #--- Find position of In-Line comment, avoiding comments inside strings
        inString = false
        stringChar = ""
        for i = 1 to len(tempLine)
            char = substr(tempLine, i, 1)
            
            #--- Handle string boundaries
            if char = "'" or char = char(34)
                if not inString
                    inString = true
                    stringChar = char
                elseif char = stringChar
                    inString = false
                    stringChar = ""
                ok
                loop
            ok
            
            #--- Look for Comment Markers outside strings
            if not inString
                if i < len(tempLine) and substr(tempLine, i, 2) = "//"
                    inlineCommentPos = i
                    exit
                ok
                if substr(tempLine, i, 1) = "#"
                    inlineCommentPos = i
                    exit
                ok
            ok
        next
        
        #--- Process line with In-Line Comment
        if inlineCommentPos > 0
            codePart = trimAll(left(tempLine, inlineCommentPos - 1))
            commentPart = substr(tempLine, inlineCommentPos)
            
            if len(codePart) > 0
                #--- Process the code part normally
                processedLine = ProcessLine(codePart, indentLevel, inSwitch, switchIndentLevel, inTry, tryIndentLevel)
                #--- Add the comment part back
                finalLine = processedLine[1] + " " + commentPart
                formattedLines + finalLine
                indentLevel = processedLine[2]
                inSwitch = processedLine[3]
                switchIndentLevel = processedLine[4]
                inTry = processedLine[5]
                tryIndentLevel = processedLine[6]
                loop
            else
                #--- Just a comment line
                formattedLines + makeSpaces(indentLevel * indentSize) + trimmedLine
                loop
            ok
        ok
        
        #--- Process the line for keywords
        processedLine = ProcessLine(trimmedLine, indentLevel, inSwitch, switchIndentLevel, inTry, tryIndentLevel)
        formattedLines + processedLine[1]
        indentLevel = processedLine[2]
        inSwitch = processedLine[3]
        switchIndentLevel = processedLine[4]
        inTry = processedLine[5]
        tryIndentLevel = processedLine[6]
    next
    
    return list2str(formattedLines)

//============================ 
func ProcessLine trimmedLine, currentIndent, inSwitch, switchIndentLevel, inTry, tryIndentLevel
    #--- Check if line starts with "func" keyword - reset to position 1
    lowerLine = lower(trimmedLine)
    if startswith(lowerLine, "func ") or lowerLine = "func"
        #--- Format operators in the line
        formattedLine = FormatOperatorsInLine(trimmedLine)
        #--- Func always starts at position 1 (no indentation)
        finalLine = formattedLine
        #--- Set indent level to 1 for content inside the function
        return [finalLine, 1, false, 0, false, 0]
    ok
    
    #--- Handle try statement entry
    if startswith(lowerLine, "try ") or lowerLine = "try"
        formattedLine = FormatOperatorsInLine(trimmedLine)
        finalLine = makeSpaces(currentIndent * indentSize) + formattedLine
        return [finalLine, currentIndent + 1, inSwitch, switchIndentLevel, true, currentIndent]
    ok
    
    #--- Handle catch statement within try
    if inTry and (startswith(lowerLine, "catch ") or lowerLine = "catch")
        formattedLine = FormatOperatorsInLine(trimmedLine)
        finalLine = makeSpaces(tryIndentLevel * indentSize) + formattedLine
        return [finalLine, tryIndentLevel + 1, inSwitch, switchIndentLevel, inTry, tryIndentLevel]
    ok
    
    #--- Handle end of try/catch
    if inTry and (startswith(lowerLine, "end ") or lowerLine = "end")
        formattedLine = FormatOperatorsInLine(trimmedLine)
        finalLine = makeSpaces(tryIndentLevel * indentSize) + formattedLine
        return [finalLine, tryIndentLevel, inSwitch, switchIndentLevel, false, 0]
    ok
    
    #--- Handle switch statement entry
    if startswith(lowerLine, "switch ") or lowerLine = "switch"
        formattedLine = FormatOperatorsInLine(trimmedLine)
        finalLine = makeSpaces(currentIndent * indentSize) + formattedLine
        return [finalLine, currentIndent + 1, true, currentIndent + 1, inTry, tryIndentLevel]
    ok
    
    #--- Handle case and on statements within switch
    if inSwitch and (startswith(lowerLine, "case ") or lowerLine = "case" or startswith(lowerLine, "on ") or lowerLine = "on")
        formattedLine = FormatOperatorsInLine(trimmedLine)
        finalLine = makeSpaces(switchIndentLevel * indentSize) + formattedLine
        return [finalLine, switchIndentLevel + 1, inSwitch, switchIndentLevel, inTry, tryIndentLevel]
    ok
    
    #--- Handle off statement (default case)
    if inSwitch and (startswith(lowerLine, "off ") or lowerLine = "off")
        formattedLine = FormatOperatorsInLine(trimmedLine)
        finalLine = makeSpaces(switchIndentLevel * indentSize) + formattedLine
        return [finalLine, switchIndentLevel + 1, inSwitch, switchIndentLevel, inTry, tryIndentLevel]
    ok
    
    #--- Handle end of switch
    if inSwitch and (startswith(lowerLine, "end ") or lowerLine = "end")
        #--- Check if this ends the switch
        formattedLine = FormatOperatorsInLine(trimmedLine)
        finalLine = makeSpaces((switchIndentLevel - 1) * indentSize) + formattedLine
        return [finalLine, switchIndentLevel - 1, false, 0, inTry, tryIndentLevel]
    ok
    
    #--- Check if line starts with a closing brace
    if startswith(trimmedLine, "}")
        #--- Decrease indent for closing brace
        if currentIndent > 0
            currentIndent = currentIndent - 1
        ok
        formattedLine = FormatOperatorsInLine(trimmedLine)
        finalLine = makeSpaces(currentIndent * indentSize) + formattedLine
        return [finalLine, currentIndent, inSwitch, switchIndentLevel, inTry, tryIndentLevel]
    ok
    
    #--- Check if line starts with a deindent keyword (like "end")
    shouldDeindent = CheckKeywordMatch(trimmedLine, deindentKeywords)
    
    #--- Check if line starts with a neutral keyword (like "else", "elseif")
    isNeutral = CheckKeywordMatch(trimmedLine, neutralKeywords)
    
    #--- FIXED: Handle "else" and "elseif" specially - they should align with their matching "if"
    if isNeutral and (startswith(lowerLine, "else ") or lowerLine = "else" or startswith(lowerLine, "elseif "))
        #--- For "else" and "elseif", use the same indent as the matching "if"
        if currentIndent > 0
            lineIndent = currentIndent - 1
        else
            lineIndent = 0
        ok
        #--- Format operators in the line
        formattedLine = FormatOperatorsInLine(trimmedLine)
        #--- Create final formatted line with proper indentation
        finalLine = makeSpaces(lineIndent * indentSize) + formattedLine
        #--- After else/elseif, increase indent for the next line
        return [finalLine, currentIndent, inSwitch, switchIndentLevel, inTry, tryIndentLevel]
    ok
    
    #--- Adjust indent level for this line
    lineIndent = currentIndent
    
    #--- Decrease indent for deindent keywords (like "end", "next", "ok")
    if shouldDeindent and currentIndent > 0
        lineIndent = currentIndent - 1
        currentIndent = currentIndent - 1
    ok
    
    #--- Format operators in the line
    formattedLine = FormatOperatorsInLine(trimmedLine)
    
    #--- Create final formatted line with indentation
    finalLine = makeSpaces(lineIndent * indentSize) + formattedLine
    
    #--- Check if line should increase indent for next line
    shouldIndent = CheckKeywordMatch(trimmedLine, indentKeywords)
    
    #--- Check if line ends with opening brace
    hasOpeningBrace = right(trimAll(trimmedLine), 1) = "{"
    
    if shouldIndent or hasOpeningBrace
        currentIndent = currentIndent + 1
    ok
    
    return [finalLine, currentIndent, inSwitch, switchIndentLevel, inTry, tryIndentLevel]

//============================ 
func FormatOperatorsInLine line
    if not formatOperators
        return line
    ok
    
    result = ""
    i = 1
    inString = false
    stringChar = ""
    
    while i <= len(line)
        char = substr(line, i, 1)
        
        #--- Handle string boundaries
        if char = "'" or char = char(34)
            if not inString
                inString = true
                stringChar = char
            elseif char = stringChar
                inString = false
                stringChar = ""
            ok
            result = result + char
            i = i + 1
            loop
        ok
        
        #--- Skip operator formatting inside strings
        if inString
            result = result + char
            i = i + 1
            loop
        ok
        
        #--- Check for two-character operators first
        if i < len(line)
            twoChar = substr(line, i, 2)
            if IsInList(twoChar, twoCharOperators)
                #--- Handle increment/decrement operators specially
                if twoChar = "++" or twoChar = "--"
                    result = result + twoChar
                else
                    #--- Add spaces around other two-character operators
                    if len(result) > 0 and right(result, 1) != " "
                        result = result + " "
                    ok
                    result = result + twoChar
                    if i + 2 <= len(line) and substr(line, i + 2, 1) != " "
                        result = result + " "
                    ok
                ok
                i = i + 2
                loop
            ok
        ok
        
        #--- Check for one-character operators
        if IsInList(char, oneCharOperators)
            #--- Add spaces around one-character operators
            if len(result) > 0 and right(result, 1) != " "
                result = result + " "
            ok
            result = result + char
            if i < len(line) and substr(line, i + 1, 1) != " "
                result = result + " "
            ok
        else
            result = result + char
        ok
        
        i = i + 1
    end
    
    return result

//============================ 
func CheckKeywordMatch line, keywords
    lowerLine = lower(line)
    for keyword in keywords
        if startswith(lowerLine, keyword + " ") or lowerLine = keyword
            return true
        ok
    next
    return false

//============================ 
func startswith text, prefix
    if len(text) < len(prefix)
        return false
    ok
    return left(text, len(prefix)) = prefix

//============================ 
func makeSpaces count
    result = ""
    for i = 1 to count
        result = result + " "
    next
    return result

//============================ 
func trimAll text
    #--- Remove leading whitespace
    while len(text) > 0 and (left(text, 1) = " " or left(text, 1) = char(9))
        text = substr(text, 2)
    end
    
    #--- Remove trailing whitespace
    while len(text) > 0 and (right(text, 1) = " " or right(text, 1) = char(9))
        text = left(text, len(text) - 1)
    end
    
    return text

//============================ 
func tabsToSpaces text, tabSizeParam
    if tabSizeParam = null or tabSizeParam <= 0
        tabSizeParam = 4
    ok
    
    result = ""
    for i = 1 to len(text)
        char = substr(text, i, 1)
        if char = char(9)  #--- Tab character
            spacesNeeded = tabSizeParam - ((len(result) % tabSizeParam))
            result = result + makeSpaces(spacesNeeded)
        else
            result = result + char
        ok
    next
    return result

//============================ 
func IsInList item, list
    for element in list
        if element = item
            return true
        ok
    next
    return false

//============================ 
func ValidateRingCode codeText
    lines  = str2list(codeText)
    errors = []
    openBlocks = 0
    lineNum    = 0
    
    for line in lines
        lineNum = lineNum + 1
        
        if useSpacesOnly
            line = tabsToSpaces(line, tabSize)
        ok
        
        trimmedLine = lower(trimAll(line))
        
        #--- Skip comments and empty lines
        if len(trimmedLine) = 0 or startswith(trimmedLine, "#") or startswith(trimmedLine, "//")
            loop
        ok
        
        #--- Check for opening blocks
        for keyword in indentKeywords
            if keyword = "func"    // <<<<< Indent Back to Position 1
                openBlocks = 1     // Blocks 1 Indent
                exit				
            elseif startswith(trimmedLine, keyword + " ") or trimmedLine = keyword
                openBlocks = openBlocks + 1
                exit				
            ok
        next
        
        #--- Check for closing blocks
        for keyword in deindentKeywords
            if startswith(trimmedLine, keyword + " ") or trimmedLine = keyword
                openBlocks = openBlocks - 1
                if openBlocks < 0
                    errors + ("Line " + lineNum + ": Unexpected " + keyword + " - no matching opening block")
                    openBlocks = 0
                ok
                exit
            ok
        next
    next
    
    if openBlocks > 0
        errors + ("ERROR: " + openBlocks + " unclosed blocks detected")
    ok
    
    return errors

#--- Interactive formatter with comprehensive test suite
//============================ 
func InteractiveFormatter
    see "==========================================" + nl
    see "    RING CODE FORMATTER v2.3" + nl
    see "    Interactive Version with Test Suite" + nl
    see "==========================================" + nl + nl
    
    while true
        see "Available Options:" + nl
		
        See "  1. Read from File" + nl       
		see "  2. Format code from manual input" + nl
        see "  3. Run basic formatting test" + nl
        see "  4. Test operator formatting" + nl
        see "  5. Test quote handling" + nl
        see "  6. Test complex nested structures" + nl
        see "  7. Test comment preservation" + nl
        see "  8. Test tab/space conversion" + nl
        see "  9. Test GUI formatting" + nl
        see " 10. Validate code structure" + nl
        see " 11. Configuration settings" + nl
        see " 12. About this formatter" + nl
        see " 13. Exit" + nl + nl 
        see "Enter your choice (1-13): "
        give choice
        see nl
        
        switch choice
		case "1"
            ReadFromFile()
        case "2"
            HandleManualInput()
        case "3"
            TestBasicFormatting()
        case "4"
            TestOperatorFormatting()
        case "5"
            TestQuoteHandling()
        case "6"
            TestNestedStructures()
        case "7"
            TestCommentPreservation()
        case "8"
            TestTabSpaceConversion()
        case "9"
            TestGUIFormatting()
        case "10"
            HandleValidation()
        case "11"
            ShowConfiguration()
        case "12"
            ShowAbout()
        case "13"
            see "Thank you for using Ring Code Formatter!" + nl
            see "Goodbye!" + nl
            exit
        case "13"
            ReadFromFile()
        other
            see "Invalid choice. Please select 1-13." + nl
        end
        
        see nl + "Press Enter to continue..."
        give dummy
        see nl
    end
	
//==================================
// Read From File use Dialogue

//============================ 
func ReadFromFile()

   //=============================== 
   // Use Dialog to select file.ring
  
    filters  = "Source:ring;Text:txt"
    filepath = dialog_file(DIALOG_OPEN, ".", "", filters)

    if len(filepath) > 0
       see "Selected file: " + filepath + nl+nl
    ok  
	
  
    //------------------------------------------
    // Format lines from File to List of Strings
   
    testCode  = read(filepath)	
	
    ProcessAndDisplayCode(testCode)	
	
end

//==================================	

//============================ 
func HandleManualInput
    see "MANUAL CODE INPUT" + nl
    see "Type your Ring code below (type END on a new line when finished):" + nl
    see copy("=",50) + nl        //  <<<<< Boudary Line of ===
    
    codeText = ""
    lineCount = 0
    while true
        lineCount = lineCount + 1
        see ""+ lineCount + "> "
        give inputLine
        if upper(trimAll(inputLine)) = "END"
            exit
        ok
        codeText = codeText + inputLine + nl
    end
    
    if len(trimAll(codeText)) = 0
        see "No code entered." + nl
        return
    ok
    
    see nl + "Processing your code..." + nl
    ProcessAndDisplayCode(codeText)

//============================ 
func ProcessAndDisplayCode codeText
    see nl + "Original code:" + nl
    see copy("=",50) + nl        //  <<<<< Boundary Line of ===
    see codeText + nl
    
    #--- Validate first
    errors = ValidateRingCode(codeText)
    if len(errors) > 0
        see "WARNING - Code validation errors:" + nl
		MsgWarning + "WARNING - Code validation errors: " +" | "  // <<<<< ADD to List
		
        for error in errors
            see "  " + error + nl
			MsgErrors + error +" | "
			
        next
        see nl
    ok
    
    #--- Format the code
    formattedCode = FormatRingCode(codeText)
    
	see nl+"<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>" + nl 
	See    "<<<                                  >>>" + nl
    see    "<<<        FORMATTED CODE:           >>>" + nl
	See    "<<<                                  >>>" + nl
	see    "<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>" + nl + nl
	
    see formattedCode + nl
    
    #--- Show statistics
    originalLines = len(str2list(codeText))
    formattedLines = len(str2list(formattedCode))
    see nl + "Statistics:" + nl
    see "  Original lines: " + originalLines + nl
    see "  Formatted lines: " + formattedLines + nl
    see "  Indent size: " + indentSize + " spaces" + nl
	
	See nl
	See "MsgWarning: "+nl  See MsgWarning     // <<<<< Display Warnings List
	See "MsgErrors.: "+nl  See MsgErrors      // <<<<< Display Errors List
	
	MsgWarning = []  // <<<<< Reset Warnings List
    MsgErrors  = []  // <<<<< Reset Errors List
	

//============================ 
func TestBasicFormatting
    see "=== BASIC FORMATTING TEST ===" + nl + nl
    
    testCode = '
if x > 10
see "x is greater than 10"
if y < 5
see "y is less than 5"
else
see "y is 5 or greater"
end
else
see "x is 10 or less"
end

for i = 1 to 10
   if i % 2 = 0
      see "Even: " + i
   else
      see "Odd: " + i
   ok
next
'
    
    see "Testing basic if/else and for loop formatting..." + nl
    ProcessAndDisplayCode(testCode)

//============================ 
func TestOperatorFormatting
    see "=== OPERATOR FORMATTING TEST ===" + nl + nl
    
    testCode = '
#--- Testing operator formatting
x=5
y+=10
z*=2
result=x+y*z

#--- Increment and decrement
counter=0
counter++
++counter
value--
--value

#--- Comparisons
if x==5 and y>=10
see "conditions met"
end

#--- Complex expressions
sum=a+b*c/d
flag=x>0&&y<100||z!=0
'
    
    see "Testing operator spacing and increment/decrement operators..." + nl
    ProcessAndDisplayCode(testCode)

//============================ 
func TestQuoteHandling
    see "=== QUOTE HANDLING TEST ===" + nl + nl
    
    testCode = '
#--- Testing quote preservation
see "Hello with double quotes"
see ' + "'" + 'Hello with single quotes' + "'" + '

#--- Mixed quotes
message = "String with ' + "'" + 'single' + "'" + ' quotes inside"
response = ' + "'" + 'String with " double " quotes inside' + "'" + '

#--- Operators inside strings should not be formatted
see "x=5 and y+=10 should stay as-is"
see ' + "'" + 'a==b and c!=d should stay as-is' + "'" + '

if name = "John"
see "Welcome " + name
else
see "Unknown user"
end
'
    
    see "Testing quote preservation and operators inside strings..." + nl
    ProcessAndDisplayCode(testCode)

//============================ 
func TestNestedStructures
    see "=== NESTED STRUCTURES TEST ===" + nl + nl
    
    testCode = '
class Calculator
result
//============================ 
func add a, b
result = a + b
if result > 100
see "Large result: " + result
for i = 1 to 3
see "Step " + i
if i = 2
see "Middle step"
end
next
else
see "Small result: " + result
end
return result

//============================ 
func multiply a, b
result = a * b
switch result
case 0
see "Zero result"
case 1 to 10
see "Small product"
off
see "Large product"
end
return result

//============================ 
func divide a, b
result = a / b
switch result
on 0
see "Division by zero"
on 1
see "Equal values"
off
see "Normal division"
end
return result
end
'
    
    see "Testing nested class, function, and control structures with switch/case/on/off..." + nl
    ProcessAndDisplayCode(testCode)

//============================ 
func TestCommentPreservation
    see "=== COMMENT PRESERVATION TEST ===" + nl + nl
    
    testCode = '
#--- This is a header comment
//============================ 
func testFunction
#--- Inside function comment
x = 5  #--- End of line comment

// PlayBoard - Start Formation:
// Pos     0        1         2
// Pos     12345678901234567890

/* This is a 
   multi-line block 
   comment */

for dir = 1 to 8
   if board[pos + dir] = target
      ok // if tgt
   next // for dir
ok // if board

if x > 0
#--- Nested comment
// Another nested comment
see "positive" // inline comment here
end

#--- Final comment
// Final C-style comment
'
    
    see "Testing comment preservation and proper indentation (both # and // styles, including inline)..." + nl
    ProcessAndDisplayCode(testCode)

//============================ 
func TestTabSpaceConversion
    see "=== TAB/SPACE CONVERSION TEST ===" + nl + nl
    
    #--- Create test code with actual tabs (using char(9))
    testCode = "if x > 0" + nl + char(9) + "see " + char(34) + "has tab" + char(34) + nl + "    see " + char(34) + "has spaces" + char(34) + nl + char(9) + "    see " + char(34) + "mixed tabs and spaces" + char(34) + nl + "end" + nl
    
    see "Testing tab to space conversion..." + nl
    see "Original code contains tabs and mixed indentation." + nl
    ProcessAndDisplayCode(testCode)

//============================ 
func HandleValidation
    see "=== CODE STRUCTURE VALIDATION ===" + nl
    see "Enter Ring code to validate (type END when finished):" + nl
    see copy("=",50) + nl        //  <<<<< Boundary Line of ===
    
    codeText = ""
    while true
        give inputLine
        if upper(trimAll(inputLine)) = "END"
            exit
        ok
        codeText = codeText + inputLine + nl
    end
    
    if len(trimAll(codeText)) = 0
        see "No code entered." + nl
        return
    ok
    
    see nl + "Validating code structure..." + nl
    errors = ValidateRingCode(codeText)
    
    if len(errors) = 0
        see "SUCCESS: Code validation passed - no structural errors found!" + nl
    else
        see "ERRORS FOUND: Code validation failed:" + nl
        for error in errors
            see "  - " + error + nl
        next
    ok

//============================ 
func ShowConfiguration
    see "=== CURRENT CONFIGURATION ===" + nl + nl
    see "Settings:" + nl
    see "  Indent size: " + indentSize + " spaces" + nl
    see "  Tab size: " + tabSize + " spaces" + nl
    see "  Convert tabs to spaces: " + useSpacesOnly + nl
    see "  Format operators: " + formatOperators + nl
    see "  Max line length: " + maxLineLength + " characters" + nl + nl
    
    see "Supported keywords:" + nl
    see "  Indent keywords: "
    for i = 1 to len(indentKeywords)
        see indentKeywords[i]
        if i < len(indentKeywords)
            see ", "
        ok
    next
    see nl
    
    see "  Deindent keywords: "
    for i = 1 to len(deindentKeywords)
        see deindentKeywords[i]
        if i < len(deindentKeywords)
            see ", "
        ok
    next
    see nl + nl
    
    see "Note: Ring is case-insensitive, so keywords work in any case." + nl

//============================ 
func ShowAbout
    see "=== ABOUT RING CODE FORMATTER ===" + nl
    see "Version: v2.3 - Interactive Test Suite Edition" + nl
    see "Language: Ring Programming Language" + nl + nl
    
    see "Features:" + nl
    see "  - Smart keyword-based indentation" + nl
    see "  - Operator spacing (including ++/--)" + nl
    see "  - Quote and string preservation" + nl
    see "  - Comment preservation" + nl
    see "  - Tab to space conversion" + nl
    see "  - Code structure validation" + nl
    see "  - Comprehensive test suite" + nl
    see "  - Function reset to position 1" + nl + nl
    
    see "Test Suite Includes:" + nl
    see "  1. Basic formatting (if/else/for/while)" + nl
    see "  2. Operator formatting (all operators)" + nl
    see "  3. Quote handling (single/double quotes)" + nl
    see "  4. Nested structures (classes/functions)" + nl
    see "  5. Comment preservation (all types)" + nl
    see "  6. Tab/space conversion" + nl
    see "  7. Code validation" + nl + nl
    
    see "Ring Language Features:" + nl
    see "  - Case insensitive" + nl
    see "  - Dynamic typing" + nl
    see "  - Multiple programming paradigms" + nl
    see "  - Simple and flexible syntax" + nl
	
	

//======================

#--- Start the program
main()
