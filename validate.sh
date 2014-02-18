#!/bin/bash
rm -rf v
for dir in $(ls -d */)
do
  mkdir -p v/$dir
done

files=$(find * -type f -name '*.html')
for file in $files
do
  curl -F uploaded_file=@$file http://validator.w3.org/check -D v/$file
  sleep 1
done

PAGES_WITH_ERRORS=0

for file in $(find v -type f -name '*.html')
do
  Status=$(grep X-W3C-Validator-Status $file | sed 's/X-W3C-Validator-Status: //g' | sed 's/Valid/0/g' | sed 's/Invalid/1/g' | tr -d [:space:])
  Recursion=$(grep X-W3C-Validator-Recursion $file | sed 's/X-W3C-Validator-Recursion: //g' | sed 'y/01/10/' | tr -d [:space:])
  Warnings=$(grep X-W3C-Validator-Warnings $file | sed 's/X-W3C-Validator-Warnings: //g' | tr -d [:space:])
  Errors=$(grep X-W3C-Validator-Errors $file | sed 's/X-W3C-Validator-Errors: //g' | tr -d [:space:])

  PAGES_WITH_ERRORS=`expr $PAGES_WITH_ERRORS + $Status + $Recursion + $Warnings \> 0 + $Errors \> 0`

  # echo "=${file}="
  # echo "=${Status}="
  # echo "=${Recursion}="
  # echo "=${Warnings}="
  # echo "=${Errors}="
  # echo $((Status + Recursion + (($Warnings > 0)) + (($Errors > 0)) ))

  echo "<testsuites tests=\"4\" failures=\"`expr $Status + $Recursion + $Warnings \> 0 + $Errors \> 0`\" disabled=\"0\" errors=\"0\" time=\"0.0\" name=\"$f\">" > $file
  echo "<testsuite name=\"$f\" status=\"run\" time=\"0\" errors=\"`expr $Warnings \> 0 + $Errors \> 0`\">" >> $file
  if [ "$Status" -eq 0 ]
  then
    echo "  <testcase name=\"W3C_Validator_Status\" status=\"run\" time=\"0\" />" >> $file
  else
    echo "  <testcase name=\"W3C_Validator_Status status=\"run\" time=\"0\" \">" >> $file
    echo "    <failure message=\"W3 Validator Status is Invalid\" type=\"\"></failure>" >> $file
    echo "  </testcase>" >> $file
  fi
  if [ "$Recursion" -eq 0 ]
  then
    echo "  <testcase name=\"W3C_Validator_Recursion\" status=\"run\" time=\"0\" />" >> $file
  else
    echo "  <testcase name=\"W3C_Validator_Recursion\" status=\"run\" time=\"0\" >" >> $file
    echo "    <failure message=\"Recursion: ${Recursion}\" type=\"\"></failure>" >> $file
    echo "  </testcase>" >> $file
  fi
  if [ "$Warnings" -eq 0 ]
  then
    echo "  <testcase name=\"W3C_Validator_Warnings\" status=\"run\" time=\"0\" />" >> $file
  else
    echo "  <testcase name=\"W3C_Validator_Warnings\" status=\"run\" time=\"0\" >" >> $file
    echo "    <failure message=\"Warnings: ${Warnings}\" type=\"\"></failure>" >> $file
    echo "  </testcase>" >> $file
  fi
  if [ "$Errors" -eq 0 ]
  then
    echo "  <testcase name=\"W3C_Validator_Errors\" status=\"run\" time=\"0\" />" >> $file
  else
    echo "  <testcase name=\"W3C_Validator_Errors\" status=\"run\" time=\"0\" >" >> $file
    echo "    <failure message=\"Errors: ${Errors}\" type=\"\"></failure>" >> $file
    echo "  </testcase>" >> $file
  fi
  echo "</testsuite>" >> $file
  echo "</testsuites>" >> $file

done

echo "# pages with errors: ${PAGES_WITH_ERRORS}"
exit $PAGES_WITH_ERRORS
