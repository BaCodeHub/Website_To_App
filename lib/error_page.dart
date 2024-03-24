import 'package:flutter/material.dart';
import 'main.dart';

class CustomErrorPage extends StatelessWidget {
  const CustomErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        color: temaRengi,
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error,
              size: 80,
              color: karsitrenk,
            ),
            const SizedBox(height: 20),
            Text(
              "Sayfa yüklenemedi ☠️",
              style: TextStyle(
                  color: karsitrenk, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MyWebView()),
                );
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                  karsitrenk,
                ),
                overlayColor: MaterialStateProperty.all<Color>(
                  Colors.black.withOpacity(0.1),
                ),
              ),
              child: Text(" Yeniden Yükle ", style: TextStyle(color: temaRengi)),
            ),
          ],
        ),
      ),
    );
  }
}
