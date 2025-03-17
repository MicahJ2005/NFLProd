/*
Copyright (c) 2012, Ardent Software, LLC.
All rights reserved.
 
Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:
 
* Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.
* Neither the name of the Ardent Software, LLC. nor the names of its contributors
may be used to endorse or promote products derived from this software
without specific prior written permission.
 
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
OF THE POSSIBILITY OF SUCH DAMAGE.
 
****
 
Note that this code may require some work before you can deploy it to a standard org.
*/
public class UtilitySoundex{
	public static void doNothing() {}
	/**public static integer soundexLength = 4;
	 
	private static map<String,String> soundexMap = new map<String,String>{
		'A'=>'0','B'=>'1','C'=>'2','D'=>'3','E'=>'0',
		'F'=>'1','G'=>'2','H'=>'0','I'=>'0','J'=>'2',
		'K'=>'2','L'=>'4','M'=>'5','N'=>'5','O'=>'0',
		'P'=>'1','Q'=>'2','R'=>'6','S'=>'2','T'=>'3',
		'U'=>'0','V'=>'1','W'=>'0','X'=>'2','Y'=>'0',
		'Z'=>'2'};
		
	public static string toSoundex(String input){
		String prevChar = ' ';
		if (input == NULL || input.length() == 0){
			return input;
		}
	
		String normStr = input.toUpperCase();
		//Append first character to encoded string
		String soundexStr = normStr.substring(0,1);
		integer strLength = normStr.length();
		for (integer i=1; i<strLength && soundexStr.length()<soundexLength; i++){
			String key=normStr.substring(i,i+1);
			String soundexChar = soundexMap.get(key);
			 
			if (soundexChar != NULL && !soundexChar.equals('0') && !soundexChar.equals(prevChar)){
				soundexStr = soundexStr+soundexChar;
				prevChar = soundexChar;
			}
		}
		//Pad soundex string if the length is less than 4
		while (soundexStr.length() < soundexLength){
			soundexStr = soundexStr+'0';
		}
		return soundexStr;
	}
	*/
}