
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webrevue/constants/keys.dart';
import 'package:webrevue/constants/loading_dialog.dart';
import 'package:webrevue/home/CompoundList.dart';
import 'package:webrevue/model/AnswerModal.dart';
import 'package:webrevue/model/CompoundModal.dart';
import 'package:webrevue/model/LikeUnlikeModal.dart';
import 'package:webrevue/model/MessagingModal.dart';
import 'package:webrevue/model/QuestionModal.dart';
import 'package:webrevue/model/ReportModal.dart';
import 'package:webrevue/model/ReviewModal.dart';
import 'package:webrevue/model/UserModal.dart';
import 'package:webrevue/route/routing_constant.dart';

import 'ServerDetails.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

class Webservice{

  static Future<bool> registerRequest(BuildContext context,UserModal userModal) async{
    var request = userModal.toJson();
    print(request);
    var response = await http.post(Uri.parse(ServerDetails.register_request),
        body: convert.jsonEncode(request),
        headers: {
          "content-type": "application/json",
          "accept": "application/json"
        });

    var jsonResponse = convert.jsonDecode(response.body);

    if(jsonResponse["status"]== true &&
        jsonResponse["errorCode"] ==1 ){

      return true;
    }else{
      print("not register");
      return false;
    }
  }

  static Future<bool> loginRequest(BuildContext context,UserModal userModal)async{
    var request ={};
    request["email"] = userModal.email;
    request["password"] = userModal.password;
    print(request);
    var response = await http.post(Uri.parse(ServerDetails.login_request),
        body: convert.jsonEncode(request),
        headers: {
          "content-type": "application/json",
          "accept": "application/json"
        });

    var jsonResponse = convert.jsonDecode(response.body);
    print(jsonResponse);


    if(jsonResponse["status"]==true &&
        jsonResponse["errorCode"] == 1){

      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      sharedPreferences.setString("userId", jsonResponse["user"]["_id"]);
      sharedPreferences.setString("name", jsonResponse["user"]["firstname"]+" " +jsonResponse["user"]["lastname"]);
      sharedPreferences.setString("email",jsonResponse["user"]["email"]);
      sharedPreferences.setBool("isLoggedIn", true);

      // displayAlertDialog(context,content: jsonResponse["message"],title: "Login");
      return true;
    }
    else if(jsonResponse["status"] == false &&
        jsonResponse["errorCode"]==0
        && jsonResponse["message"] == "Password Not Match"){

      // displayAlertDialog(context,content: jsonResponse["message"],title: "Login");
      return false;
    }

    else if(jsonResponse["status"] == false &&
        jsonResponse["errorCode"]==0
        && jsonResponse["message"] =="User Not Found"){

      // displayAlertDialog(context,content: jsonResponse["message"],title: "Login");
      return false;
    }
  }


  static Future<dynamic>  getCompoundRequest(BuildContext context,List cList,String id)async{

    var request ={};
    request["lastObjectID"]= id;
    request["category"] = "Any";
    request["amenities"] = [];
    // if(radius>0 && radius<30 && currentPosition!=null)
    // {
    //   request["radius"]=radius;
    //   request["coordinates"]=[currentPosition.latitude,currentPosition.longitude];
    // }

    // print(convert.jsonEncode(request));
    var response = await http.post(Uri.parse(ServerDetails.get_compound_request),
        body: convert.jsonEncode(request),
        headers: {
          "content-type": "application/json",
          "accept": "application/json"
        });

    cList.clear();
    // print(response.body);
    var jsonResponse = convert.jsonDecode(response.body);
    print(jsonResponse);
    // List tempList = [];
    // CompoundModal compoundModal;
    if(jsonResponse["status"]==true &&
        jsonResponse["fetchCode"]==1){
      List list = jsonResponse["compoundList"];
      list.forEach((element) {
      CompoundModal  compoundModal = new CompoundModal.fromJson(element);
        cList.add(compoundModal);
      });
    }else if(jsonResponse["status"]==false &&
        jsonResponse["fetchCode"]==2){
      displayAlertDialog(context,content: "Unable to Fetch Compound",title: "Compounds");
    }
   }


  static Future<CompoundModal> getCompoundDetails(String id)async{
    var request ={};
    request["id"] = id;
    var response = await http.post(Uri.parse(ServerDetails.get_compound_detail_request),
        body:convert.jsonEncode(request),
        headers: {
          "content-type": "application/json",
          "accept": "application/json"
        });
    var jsonResponse  = convert.jsonDecode(response.body);
    CompoundModal compoundModal;
    // print(jsonResponse);
    if(jsonResponse["status"] == true
        &&jsonResponse["errorCode"] ==1){
      compoundModal = CompoundModal.fromJson(jsonResponse["compoundModal"]);

    }return compoundModal;

  }

  static Future<dynamic> fetchAllReviews(BuildContext context,String id,List rList)async{
    var request ={};
    request["compoundID"] = id;
    var response = await http.post(Uri.parse(ServerDetails.get_AllReviews),
        body:convert.jsonEncode(request),
        headers: {
          "content-type": "application/json",
          "accept": "application/json"
        });

    rList.clear();
    var jsonResponse = convert.jsonDecode(response.body);
    if(jsonResponse["status"] == true){
      // print(jsonResponse);
      List list = jsonResponse["reviewList"];
      ReviewModal reviewModal;
      list.forEach((element) {
        reviewModal = new ReviewModal.fromJson(element);
        rList.add(reviewModal);

      });

    }
  }


  static Future<dynamic> getAllRequestedQuestions (List questionsList,String compoundID) async{
    var request ={};
    request["compoundID"] = compoundID;
    var response  = await http.post(Uri.parse(ServerDetails.get_All_Questions),
        body: convert.jsonEncode(request), headers: {
          "content-type": "application/json",
          "accept": "application/json"
        });

    questionsList.clear();
    var jsonResponse = convert.jsonDecode(response.body);
    if(jsonResponse["errorCode"]==0 && jsonResponse["status"] == true){
      List list = jsonResponse["questionsList"];
      QuestionModal questionModal;
      list.forEach((element) {
        questionModal = new QuestionModal();
        questionModal.compoundID = element["compoundID"];
        questionModal.userName = element["userName"];
        questionModal.userID = element["userID"];
        questionModal.question = element["question"];
        questionModal.id = element["_id"];
        // questionModal.timestamp = element["timestamp"];

        List list =   element["answersList"];
        AnswerModal answerModal;
        List<AnswerModal> ansList =[];
        list.forEach((ansElement) {
          answerModal = AnswerModal.fromJson(ansElement);
          ansList.add(answerModal);
        });
        questionModal.answerList = ansList;
        questionsList.add(questionModal);
      });
    }
  }

  static Future<dynamic> postQuestionRequest(BuildContext context,MessagingModal messagingModal)async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    messagingModal.userName = sharedPreferences.getString("name");
    messagingModal.userID = sharedPreferences.getString("userId");
    var request = messagingModal.toJson();
    var response = await http.post(Uri.parse(ServerDetails.post_New_Question),
        body: convert.jsonEncode(request),
        headers: {
          "content-type": "application/json",
          "accept": "application/json"
        });

    var jsonResponse = convert.jsonDecode(response.body);
    print(jsonResponse);
    if(jsonResponse["status"] == true && jsonResponse["statusCode"]==0){
      Navigator.pop(context);
      displayAlertDialog(context,content: "Post Question Successful",
          title: "Post Question");
    }else{
      displayAlertDialog(context,content: "Unable to Post Question",
          title: "Post Question");

    }

    GlobalKeys.postQuestionClassKey.currentState.getAllQuestions();
  }


  static Future<dynamic> getAllAnswersRequest(List ansList,String qID) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();

    var request = {};
    request["questionID"]= qID;
    request["userID"] = prefs.getString("userID");
    var response = await http.post(Uri.parse(ServerDetails.get_All_Answers),
        body: convert.jsonEncode(request),
        headers: {
          "content-type": "application/json",
          "accept": "application/json"
        });

    ansList.clear();
    var jsonResponse = convert.jsonDecode(response.body);
    if(jsonResponse["errorCode"] == 0
        && jsonResponse["status"]==true){
      List list =   jsonResponse["answerList"];
      AnswerModal answerModal;
      list.forEach((ansElement) {
        answerModal = AnswerModal.fromJson(ansElement);
        ansList.add(answerModal);
      });
    }

  }

  static Future<dynamic> postAnswerRequest(BuildContext context,AnswerModal answerModal)async{
    SharedPreferences prefs= await SharedPreferences.getInstance();
    answerModal.userID = prefs.getString("userId");
    answerModal.userName = prefs.getString("name");

    var request = answerModal.toJson();
    // print(request);
    var response = await http.post(Uri.parse(ServerDetails.post_Answer),
        body: convert.jsonEncode(request),
        headers: {
          "content-type": "application/json",
          "accept": "application/json"
        });


    var jsonResponse = convert.jsonDecode(response.body);
    if(jsonResponse["status"] == true
        && jsonResponse["errorCode"]==0){

      Navigator.pop(context);
      displayAlertDialog(context,title: "Post Answer",content: "Post answer successfully");

    }else{
      displayAlertDialog(context,title: "Post Answer",content: "Unable to Post answer");

    }

    GlobalKeys.postAnswerClassKey.currentState.getAllAnswers();
  }

  static Future<dynamic> likeUnlikeRequest(BuildContext context,LikeUnlikeModal likeUnlikeModal)async{
    var request = likeUnlikeModal.toJson();
    var response = await http.post(Uri.parse(ServerDetails.update_like_dislike),
        body: convert.jsonEncode(request),
        headers: {
          "content-type": "application/json",
          "accept": "application/json"
        });

    var jsonResponse = convert.jsonDecode(response.body);
    if(jsonResponse["errorCode"] ==0
        && jsonResponse["status"]==true){
      // Fluttertoast.showToast(msg: "updated",gravity: ToastGravity.BOTTOM,
      //     toastLength: Toast.LENGTH_SHORT);
    }

  }

  static void reportAnswerRequest(BuildContext context,ReportModal reportModal)async{
    var request = reportModal.toJson();
    print(request);
    var response = await http.post(Uri.parse(ServerDetails.report_answer),
        body: convert.jsonEncode(request),
        headers: {
          "content-type": "application/json",
          "accept": "application/json"
        });


    var jsonResponse = convert.jsonDecode(response.body);
    // print(jsonResponse);
    if(jsonResponse["status"]==true &&
        jsonResponse["errorcode"] == 0){
      Navigator.pop(context);
      displayAlertDialog(context,content: "Answer Reported Successfully",title: "Report Answer");

    }else{
      Navigator.pop(context);
      displayAlertDialog(context,content: "Unable to report answer",title: "Report Answer");

    }
  }



  static Future<bool> addReviewRequest(BuildContext context,ReviewModal reviewModal)async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    var  request = new http.MultipartRequest("POST",
      Uri.parse(ServerDetails.add_Review),);
    // Map<String,String> headerMap ={"content-type":"multipart/form-data"};
    // // request.headers['content-type '] = 'multipart/form-data';
    //
    // request.headers.addAll(headerMap);

    request.fields["review"] = reviewModal.review.trim();
    request.fields["rent"] =reviewModal.price.trim();
    request.fields["floorplan"] = reviewModal.floorplan.trim();
    request.fields["reviewername"] = sharedPreferences.getString("name");
    request.fields["compoundID"] = reviewModal.compoundID ;
    request.fields["userId"] = sharedPreferences.getString("userId");
    request.fields["cons"] = reviewModal.cons.toString();
    request.fields["pros"] = reviewModal.pros.toString();
    request.fields["facility"] = reviewModal.facilities.toString();
    request.fields["management"] = reviewModal.management.toString();
    request.fields["value"] = reviewModal.value.toString();
    request.fields["location"] = reviewModal.location.toString();
    request.fields["design"] = reviewModal.design.toString();
    request.fields["rating"] = reviewModal.rating.toString();
    request.fields["compoundName"] = reviewModal.compoundName;
    request.fields["timestamp"] = reviewModal.reviewDate.toString();
    request.fields["bedRooms"]=reviewModal.bedRooms.toString();

    request.fields["bathRooms"]=reviewModal.bathRooms.toString();


    List<http.MultipartFile> newList = new List<http.MultipartFile>();
    newList = reviewModal.multipartImages;
    print(newList.length);

    request.files.addAll(newList);

    print(request.files);
    print(request.fields);

    var response = await request.send();

    // print(response.statusCode);

    response.stream.transform(utf8.decoder).listen((value) {
      print("response------------------ "+response.toString());
      print("valeue--------------"+value);
      Map map = json.decode(value);
      if(map["errorcode"] == 0 && map["status"]==true){
        GlobalKeys.compoundDetailsKey.currentState.fetchReview();

       return true;
      }
      else{
        displayAlertDialog(context,content: "Review Not Added. Please Try Again Later",);

        return false;
      }


    });



  }



}