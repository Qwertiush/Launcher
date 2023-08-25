
import '../consts/consts.dart';

class Task{

  String content = "";
  bool done = false;

  Task(this.content,this.done);

  Task.fromLineOfData(String lineOfData){
    List<String> dataLineItems = lineOfData.split(splitPattern);
    content = dataLineItems[0];

    if(dataLineItems[1] == "1"){
      done = true;
    }
    else{
      done == false;
    }
  }

  String prepareSaveForm(){
    String data = "";
    data = content + splitPattern;
    if(done){
      data += "1";
    }
    else{
      data += "0";
    }

    return data;
  }
}