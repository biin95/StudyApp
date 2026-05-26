import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RecruitmentScreen extends StatelessWidget {
  const RecruitmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('招考信息'), elevation: 0),
      body: ListView(
        children: [
          _buildSectionHeader('事业编招聘', Icons.business),
          _buildLink('全国事业单位招聘网', 'http://www.qgsydw.com', '全国事业编招聘信息聚合，最全面'),
          _buildLink('华图事业单位', 'https://sydw.huatu.com', '大型培训机构，信息更新快'),
          _buildLink('事业编招聘网', 'http://www.sybzp.cn', '全国事业编信息汇总'),
          _buildLink('中国公共招聘网（人社部）', 'http://job.mohrss.gov.cn', '人社部官方平台'),
          const Divider(height: 32),
          _buildSectionHeader('军队文职招聘', Icons.shield),
          _buildLink('解放军专业技术人才网', 'http://81rc.81.cn', '军队文职官方报名入口'),
          _buildLink('高校人才网·军队文职', 'https://www.gaoxiaojob.com/rczhaopin/junduiwenzhi', '聚合整理军队文职信息'),
        ],
      ),
    );
  }

  static Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
        ],
      ),
    );
  }

  static Widget _buildLink(String name, String url, String desc) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.open_in_browser, color: Colors.blue),
        onTap: () async {
          final uri = Uri.parse(url);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
      ),
    );
  }
}
