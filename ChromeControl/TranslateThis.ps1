$PathToFolder = split-path -parent $MyInvocation.MyCommand.Definition
cd $PathToFolder
$ConfigFolder = $PathToFolder + "\languages\Config\" 
$MyLanguage = 'en'

$Langfile = $ConfigFolder + "SupportedLanguageCodes.txt"
$LanguageList = gc -Path $Langfile #file you put the codes for languages you support, in the order they process
# If the code you use doesn't work, manually translate something, look at the url for 'tl=<code>'
# example: 'https://translate.google.com/?hl=en&tab=wT&sl=auto&tl=zh-CN&text=down&op=translate' 
# has 'tl=zh-CN' for Simplified Chinese, so put 'zh-CN' in the file

#Because Text Mesh Pro needs an example of every picture char in a text file, they're collected here 
#in this file. It is cleaned up, and (along with the language font you use) 
# you point to it in the 'TMPro font asset creator', with 'Charactor set' set to 'Character from file'.
$GraphicLanguagesCollection = $ConfigFolder + "GraphicLanguagesCollection.txt"

#you need to put the Graphic language codes for picture languages you support
$gfstr = $ConfigFolder + "GraphicLanguageCodes.txt"
$GraphicLanguageInputList = gc $gfstr 

[System.Reflection.Assembly]::LoadFrom("{0}\WebDriver.dll" -f $PathToFolder)
if ($env:Path -notlike "*;$PathToFolder*" ) {$env:Path += ";$PathToFolder"}
$service = [OpenQA.Selenium.Chrome.ChromeDriverService]::CreateDefaultService()
$service.HideCommandPromptWindow = $true
$options = New-Object OpenQA.Selenium.Chrome.ChromeOptions
$options.AddArgument("headless")
$options.AddArgument("--disable-infobars")
$ChromeDriver = New-Object OpenQA.Selenium.Chrome.ChromeDriver($service, $options)
cls

$InputText = Read-Host -Prompt "Paste string, then hit Enter..."
$InputText = $InputText -replace "\	"," "

foreach ($item in $LanguageList)
{
   cls
   "Hang On..."
  $TempText = $InputText
  $ChromeDriver.Url = "https://translate.google.com/?sl=auto&tl=" + $item + "&op=translate"
  Start-Sleep -Seconds 2
  $ChromeDriver.FindElement([OpenQA.Selenium.By]::XPath("//textarea[@aria-label='Source text']")).SendKeys($InputText)
  Start-Sleep -Seconds 3
  $Translated = $ChromeDriver.FindElements([OpenQA.Selenium.By]::XPath("//div[@aria-live='polite']")).Text
  if ($Translated -eq "")
    {
    "missed, trying again"
      Start-Sleep -Seconds 3
      $Translated = $ChromeDriver.FindElements([OpenQA.Selenium.By]::XPath("//div[@aria-live='polite']")).Text
      #Start-Sleep -Seconds 3
    }

  if ($Translated -ne "")
   {
    $Translated = $Translated -replace "content_copy`r`n", "" -replace "`r`nshare", ""
    $Translated = $Translated.Split("`r`n")
    Set-Clipboard -Value $Translated

    $LanguageName = $ChromeDriver.FindElements([OpenQA.Selenium.By]::XPath("//div[@class='akczyd']")).Text
    $LanguageName = $LanguageName.Split("`r`n")
    $TempText = $TempText -split "`n"
    $TempText[0] = $TempText[0] -replace ('\.')  -replace (' ', "_")
    
    $TempText[0] = $TempText[0] -replace ('\.')  -replace (' ', "_")

    #$TempText[0]

    "Translating To " + $LanguageName[5] + " (" + $item + ")`r`n`r`n""" + $InputText + """`r`n"
    $CopiedString = """" + $Translated +  """`r`n`r`nHas Been Copied To The Clipbpard`r`n`r`nPress The 'Enter' Key To Continue..."
  
  
    $FileName =  'languages\' + $LanguageName[5] + "_" + $item + "-" + $TempText[0]
    $FileName = $FileName -replace "\(","" -replace "\)",""  -replace "\=","" -replace " ",""
    $FileName = $FileName -replace "\	","" -replace "\.",""
    $FileName = $FileName  + ".txt"
    #$FileName
    #foreach ($item in $FileName){$item   | Format-Hex}
    #$InputText  | Format-Hex
    #$FileName  | Format-Hex
    #$Translated  | Format-Hex
    $Translated | Out-File $FileName -Encoding utf8

    $Test = $GraphicLanguageList | Select-String $item
    if ($Test -ne $null){$Translated | Out-File $GraphicLanguagesCollection -Encoding utf8 -Append}

    #$Clean up the GraphicLanguagesCollection file
    $result = gc $GraphicLanguagesCollection -Encoding UTF8 | Out-String
    $result = [system.String]::Join(" ", $result) #flatten any arrays
    $result = $result  -replace "\(",""  -replace "\)",""   -replace "\.",""  -replace "\,",""
    $result = $result -replace " ","" -replace "`r`n","" -replace "`n","" -replace "`r",""
    $result = $result  -replace "\+","" -replace "\-",""   -replace "\=","" 
    $myText = ""
    for ($i = 0; $i -lt $result.length; $i++)
      {
       $str = $result[$i]
       if ($result[$i] -match '^[a-z0-9]+$') {$myText = $myText -replace($result[$i], "")} # dump alpha-numerics
       if ($myText -notmatch $result[$i]) {$myText = $myText +$result[$i]} #remove duplicate chars
      } 
    $myText | out-file $GraphicLanguagesCollection  -Encoding UTF8

    Read-Host -Prompt $CopiedString
  }
  else {Read-Host -Prompt "missed $item again, on to next one"}
}
$ChromeDriver.Quit()



#for ($i = 0; $i -lt $myText.length; $i++){if ($result -match $myText[$i]){"good"}}
#for ($i = 0; $i -lt $result.length; $i++){if ($myText -notmatch $result[$i]){$xstr = $xstr + $result[$i]}}

#$Translated | Format-Hex
#gc -Path $FileName | Format-Hex


#if (((Format-Hex "e:\downloads\chromecontrol\languages\empty-dontdelete.txt").bytes) -eq ((Format-Hex $FileName).bytes)){"egads"}

#(Format-Hex $FileName | select * | ogv)

#$ChromeDriver.Url = 'https://translate.google.com/?sl=auto&tl=hi&op=translate'
<#
$ChromeDriver.FindElement([OpenQA.Selenium.By]::XPath("//textarea[@aria-label='Search languages']")).SendKeys('hi')
$ChromeDriver.FindElement([OpenQA.Selenium.By]::XPath("//textarea[@aria-label='Source text']")).SendKeys('Bremerton Weather')
$ChromeDriver.FindElementByXPath('//*[@id="yDmH0d"]/c-wiz/div/div[2]/c-wiz/div[2]/c-wiz/div[1]/div[2]/div[3]/c-wiz[2]/div/div[8]/div/div[1]/span[1]/span/span')

$Languages = $ChromeDriver.FindElements([OpenQA.Selenium.By]::XPath("//button[@class='VfPpkd-Bz112c-LgbsSe VfPpkd-Bz112c-LgbsSe-OWXEXe-e5LLRc-SxQuSe yHy1rc eT1oJ mN1ivc qiN4Vb KY3GZb szLmtb']"))


$Languages[1].SendKeys('')

$Languages[1].Submit()
$Languages[1].SendKeys([OpenQA.Selenium.Keys]::TAB)
$Languages[1].SendKeys([OpenQA.Selenium.Keys]::ENTER)
$Languages[1].SendKeys('French')
$ChromeDriver.SendKeys('French')

SendKeys('hi')

#$ChromeDriver.FindElement([OpenQA.Selenium.By]::XPath("//button[@class='VfPpkd-Bz112c-LgbsSe VfPpkd-Bz112c-LgbsSe-OWXEXe-e5LLRc-SxQuSe yHy1rc eT1oJ mN1ivc qiN4Vb KY3GZb szLmtb']")).Submit()

#$ChromeDriver.driver.FindElement(By Name("q"))
#$ChromeDriver.FindElementByClassName('er8xn').SendKeys('Bremerton Weather')

#$ChromeDriver.FindElementByXPath('//*[@id="tsf"]/div[2]/div[1]/div[1]/div/div[2]/input').SendKeys('Bremerton Weather')
#$ChromeDriver.FindElementByXPath('//*[@id="tsf"]/div[2]/div[1]/div[1]/div/div[2]/input').Submit()
#$temp = $ChromeDriver.FindElementByXPath('//*[@id="wob_tm"]')
$Str = $temp.Text
#cls
"`r`n`r`nThe current weather is $Str f" 
$ChromeDriver.Url = 'https://apnews.com/article/donald-trump-politics-mark-levin-coronavirus-pandemic-hacking-6080f156125a4a46edef2a6dcf826611'
#$ChromeDriver.PageSource | Out-File "GoogleSearchResults.html" -Force
#$ChromeDriver.Quit()
#Done getting weather
#>
<#
$ChromeDriver
$ChromeDriver | get-member
#>