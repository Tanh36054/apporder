import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../widget/widget_support.dart';

class AddFood extends StatefulWidget {
  const AddFood({super.key});

  @override
  State<AddFood> createState() => _AddFoodState();
}

class _AddFoodState extends State<AddFood> {
  final List<String> items = ['Ice-cream', 'Burger', 'Salad', 'Pizza'];
  String? value;
  TextEditingController nameController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController detailController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? selectedImage;
  String? base64Image;

  // Hàm chọn ảnh từ thư viện
  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      File file = File(image.path);
      List<int> imageBytes = await file.readAsBytes();
      setState(() {
        selectedImage = file;
        base64Image = base64Encode(imageBytes);
      });
    }
  }

  // Upload ảnh lên Imgur
  Future<String?> uploadToImgur(String base64Image) async {
    const String clientId =
        "a7e67cb02e6bef3"; // Thay YOUR_CLIENT_ID bằng ID của bạn
    var response = await http.post(
      Uri.parse("https://api.imgur.com/3/image"),
      headers: {"Authorization": "Client-ID $clientId"},
      body: {"image": base64Image, "type": "base64"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["data"]["link"]; // Trả về link ảnh
    } else {
      debugPrint("Error upload img: ${response.body}");
      return null;
    }
  }

  // Upload dữ liệu lên Firestore
  Future<void> uploadItem() async {
    if (base64Image == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please select img")));
      return;
    }

    String? imageUrl = await uploadToImgur(base64Image!);
    if (imageUrl == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error upload img Imgur")));
      return;
    }

    if (value == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please select a category")));
      return;
    }

    await FirebaseFirestore.instance.collection(value!).add({
      "image": imageUrl,
      "name": nameController.text,
      "price": double.tryParse(priceController.text),
      "detail": detailController.text,
      "category": value, // Lưu category đã chọn
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Add Successfull!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(
            Icons.arrow_back_ios_new_outlined,
            color: Color(0xFF373866),
          ),
        ),
        centerTitle: true,
        title: Text("Add Food", style: AppWidget.HeadLineTextFeildStyle()),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Upload the Item Picture",
                style: AppWidget.semiBoldTextFeildStyle(),
              ),
              SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: pickImage, // Gọi hàm chọn ảnh
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 1.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child:
                          selectedImage == null
                              ? Icon(Icons.camera_alt_outlined, size: 50)
                              : ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.file(
                                  selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30),
              Text("Item Name", style: AppWidget.semiBoldTextFeildStyle()),
              SizedBox(height: 10),
              buildTextField(nameController, "Enter Item Name"),

              SizedBox(height: 30),
              Text("Item Price", style: AppWidget.semiBoldTextFeildStyle()),
              SizedBox(height: 10),
              buildTextField(priceController, "Enter Item Price"),

              SizedBox(height: 30),
              Text("Description", style: AppWidget.semiBoldTextFeildStyle()),
              SizedBox(height: 10),
              buildTextField(
                detailController,
                "Enter Description",
                maxLines: 6,
              ),

              SizedBox(height: 20),
              Text("Select Item", style: AppWidget.semiBoldTextFeildStyle()),
              SizedBox(height: 10),
              buildDropdown(),

              SizedBox(height: 30),
              GestureDetector(onTap: uploadItem, child: buildButton("Add")),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Color(0xFFececf8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: AppWidget.LightTextFeildStyle(),
        ),
      ),
    );
  }

  Widget buildDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Color(0xFFececf8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          items:
              items
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
          onChanged: (value) => setState(() => this.value = value),
          dropdownColor: Colors.white,
          hint: Text("Select Item"),
          value: value,
        ),
      ),
    );
  }

  Widget buildButton(String text) {
    return Center(
      child: Material(
        elevation: 5,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          width: 150,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
