import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ReferencesDialog extends StatelessWidget {
  const ReferencesDialog({super.key});

  static const _refs = [
    _Ref(
      training: '遠近ピント切替',
      citation:
          'Ciuffreda KJ et al. "Accommodation and related clinical findings in working age myopes." Optometry and Vision Science, 88(5), 560–569, 2011.',
      url: 'https://pubmed.ncbi.nlm.nih.gov/21378592/',
    ),
    _Ref(
      training: '追従運動',
      citation:
          'Kowler E. "Eye movements: The past 25 years." Vision Research, 51(13), 1457–1483, 2011.',
      url: 'https://pubmed.ncbi.nlm.nih.gov/21035483/',
    ),
    _Ref(
      training: 'ぼけ文字識別',
      citation:
          'Polat U et al. "Training the brain to overcome the effect of aging on the human eye." Scientific Reports, 2, 278, 2012.',
      url: 'https://pubmed.ncbi.nlm.nih.gov/22355778/',
    ),
    _Ref(
      training: '寄り目トレーニング',
      citation:
          'CITT-ART Investigator Group. "Effect of Vergence/Accommodative Therapy on Reading in Children With Convergence Insufficiency." Optometry and Vision Science, 96(11), 836–849, 2019.',
      url: 'https://pubmed.ncbi.nlm.nih.gov/31688558/',
    ),
    _Ref(
      training: '視点移動',
      citation:
          'Rayner K. "Eye movements in reading and information processing: 20 years of research." Psychological Bulletin, 124(3), 372–422, 1998.',
      url: 'https://pubmed.ncbi.nlm.nih.gov/9849112/',
    ),
    _Ref(
      training: 'コントラスト順応',
      citation:
          'Owsley C et al. "Contrast sensitivity performance of eyes scheduled to undergo cataract surgery." Investigative Ophthalmology & Visual Science, 41(7), 1997–2003, 2000.',
      url: 'https://pubmed.ncbi.nlm.nih.gov/10845630/',
    ),
    _Ref(
      training: 'ガルボーパッチ',
      citation:
          'Polat U et al. "Training the brain to overcome the effect of aging on the human eye." Scientific Reports, 2, 278, 2012.',
      url: 'https://pubmed.ncbi.nlm.nih.gov/22355778/',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('参考文献'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: _refs.length,
          separatorBuilder: (context, i) => const Divider(height: 24),
          itemBuilder: (context, i) {
            final ref = _refs[i];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ref.training,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                Text(ref.citation,
                    style: const TextStyle(fontSize: 12, height: 1.6)),
                if (ref.url != null) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => launchUrl(Uri.parse(ref.url!),
                        mode: LaunchMode.externalApplication),
                    child: Text(
                      ref.url!,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.blue,
                          decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}

class _Ref {
  final String training;
  final String citation;
  final String? url;
  const _Ref({required this.training, required this.citation, this.url});
}
