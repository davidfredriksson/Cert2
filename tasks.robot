*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.Tables
Library             RPA.HTTP
Library             Collections
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    log    ${OUTPUT_DIR}${/}
    ${keys}=    Get Secret    cert2keys
    ${csv_url}=    Ask user for url of csv file
    Init robot web site
    Process orders    ${csv_url}    ${keys}[url]
    Make zip archive of all pdf files
    [Teardown]    CleanUp


*** Keywords ***
Ask user for url of csv file
    Add text input    csvurl    label=Url of csvfile?
    ${response}=    Run dialog
    RETURN    ${response.csvurl}

Init robot web site
    Open Available Browser
    ...    browser_selection=ChromiumEdge
    ...    maximized=True

Process orders
    [Arguments]    ${csv_url}    ${order_url}
    Download    ${csv_url}    overwrite=True
    ${orders}=    Read table from CSV    orders.csv    header=True

    FOR    ${order_item}    IN    @{orders}
        Wait Until Keyword Succeeds    5x    0.2 sec    Process orderitem    ${order_item}    ${order_url}
    END

Process orderitem
    [Arguments]
    ...    ${order_item}
    ...    ${order_url}
    Go To    ${order_url}
    Click Button When Visible    xpath://button[text()='OK']
    ${order_item_path}=    Set Variable    ${OUTPUT_DIR}${/}${order_item}[Order number]
    Select From List By Value    id:head    ${order_item}[Head]
    Select Radio Button    body    ${order_item}[Body]
    Input Text    xpath://input[@placeholder='Enter the part number for the legs']    ${order_item}[Legs]
    Input Text    id:address    ${order_item}[Address]
    Click Button    id:preview
    Click Button    id:order
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Screenshot    robot-preview-image    ${order_item_path}.png
    Html To Pdf    ${receipt_html}    ${order_item_path}.pdf
    Open Pdf    ${order_item_path}.pdf
    ${robot_image}=    Create List    ${order_item_path}.png
    Add Files To Pdf    ${robot_image}    ${order_item_path}.pdf
    Close Pdf

Make zip archive of all pdf files
    Archive Folder With Zip    ${OUTPUT_DIR}    ${OUTPUT_DIR}${/}pdfs.zip    include=*.pdf

CleanUp
    Close Browser
